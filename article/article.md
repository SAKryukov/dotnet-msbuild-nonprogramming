@numbering {
    enable: false
}

{title}MSBuild for Programming and Non-Programming Chores

[*Sergey A Kryukov*](https://www.SAKryukov.org)

MSBuild is a flexible tool, it can be used not only for Microsoft toolchains, and it can even be used for non-programming chores

The flexibility of MSBuild, as well as its power, is demonstrated on the non-programming task: transcoding any set of media files of different nature using FFmpeg — graphics, audio, media, captions, virtually anything. The solution is highly generalized, so it can be used for many other programming and non-programming tasks. The present article offers the reasons why such an unusual use of MSBuild is recommended.

<!-- https://www.codeproject.com/Articles/5369187/dotnet-msbuild-nonprogramming -->

<!-- copy to CodeProject from here ------------------------------------------->


## Contents{no-toc}

@toc

## Why MSBuild?

Doesn't the use of MSBuild for non-programming work look way too *esoteric*? Well, let's look closer.

I have used different scripting systems for development using some exotic languages or software development toolchains: Microsoft "CMD" batch, Python, JavaScript with [node.js](https://en.wikipedia.org/wiki/Node.js) or even badly outdated but still operational [WSF](https://en.wikipedia.org/wiki/Windows_Script_File), PowerShell, bash, and I've never been convinced to prefer one system over another one.

I also use scripting for many non-programming chores. One of my permanent activities requiring considerable scripting effort is handling different media files on different platforms: video, audio, video captions, photographs, and graphics. Recently, I decided to try out MSBuild. One of the reasons for that is that recently I took a chance to delve into BSBuild more than I usually do. Notably, it is related to my recent development found in a GitHub repository [dotnet-solution-structure](https://github.com/SAKryukov/dotnet-solution-structure).

I quickly realized that MSBuild provides serious benefits in several ways. Ultimately, they are mostly reduced to the fact that MSBuild offers [declarative programming](https://en.wikipedia.org/wiki/Declarative_programming), nothing like [imperative programming](https://en.wikipedia.org/wiki/Imperative_programming) offered by the usual scripting systems.

It is very beneficial when you have to handle sets of files located in different directories without any guaranteed directory structure. Its extended syntax for file masks is very helpful. Another powerful feature is [incremental build](https://learn.microsoft.com/en-us/visualstudio/msbuild/incremental-builds). For software development toolchains, incremental build is usual and even mandatory. But usual scripting does not offer anything like that. At the same time, a lot of non-programming development is incremental. And some processing takes a lot more time than typical software build. One notorious example is transcoding using modern video codecs. These days, the better the latency of a technology, the slower the encoding process is.

But probably the most important benefit of using MSBuild is the possibility to use it in a cross-platform way.

### Cross-Platform

The sample project provided here is cross-platform. Please see [the explanation of why it is so below](#paragraph-cross-platform).

One note on that: every time the OS "Linux" is mentioned, it actually means "non-Windows". All the elements of the solution designed to work for Linux should also work for any other platform except Windows. For this reason, all the platform-dependent conditions are calculated as `$(OS.StartsWith('Windows')` — I hope it is self-explanatory.

## Why .NET?

MSBuild can be invoked in several ways. First of all, the command is "MSBuild". MSBuild is also used for .NET projects and solutions, and then it is "dotnet build".

But I recommend using "dotnet msbuild". It is clear why "dotnet build" is not suitable for non-.NET solutions, this command does not even have the "target" option. But why "dotnet msbuild" and not "MSBuild"?

The first reason is the deployment: I don't know where your MSBuild instance is located. Developers often have several MSBuild instances installed at the same time, different versions of them. As to .NET, it is usually installed to have the application path "dotnet" accessible everywhere, and it knows the version of MSBuild supplied with it, and will launch the most appropriate version.

There is another, more subtle reason: with "dotnet msbuild", you can use very convenient .NET API functions in MSBuild property definitions. For a detailed description of this possibility, please see Microsoft documentation on [property functions](https://learn.microsoft.com/en-us/visualstudio/msbuild/property-functions).

{id=paragraph-cross-platform}And of course, one major benefit of executing MSBuild via .NET is that this method is [cross-platform](#heading-cross-platform"). It works on any platform where .NET is installed.

{id=code-run-cmd}"run.cmd":

```
dotnet msbuild a.project -t:Transcode
```

This simple command line is designed to be usable for Windows and other systems. For Linux, it should also be made executable before using it:

```
chmod -x run.cmd
```

## Code Sample

To evaluate the value of MSBuild, I create the code sample used to transcode any media supported by FFmpeg. The goal is to have an arbitrary set of media files located randomly under some directory, uniformly transcode them all, and place them in a single directory. It is done in a customizable manner: the inputs, file types, and transcoding options are placed in one "Custom" file and can be modified by the final user.

It covers most of the basic features of FFmpeg, where we need one-to-one transcoding. It does not support very tricky situations with sophisticated mapping between input and output elements, multi-pass processes where each pass should use intermediate files obtained on a previous pass, and so on. However, my code sample can be upgraded with additional project files solving those advanced problems, using the same codebase I provided with the present article.

### Why FFmpeg?

(FFmpeg)[https://en.wikipedia.org/wiki/FFmpeg] is probably the most universal and powerful suite used for the processing of a very wide range of media files. For video, it is probably the most fundamental tool. Many people who think that they don't use FFmpeg actually use it, because it lies in the base of most media editors, generators, and other media software.

It is much less true for photography and other visual arts, and a lot more for everything else, especially video.

## Implementation

### Project

In this particular project, there is only one project file. Moreover, it is never changed:

"a.project":

```{lang=XML}
&lt;Project Sdk="Microsoft.NET.Sdk"&gt;

&lt;ItemGroup&gt;
    &lt;InputFiles Include="$(InputMask)"/&gt;
&lt;/ItemGroup&gt;

&lt;/Project&gt;
```

This is the most generic project. It does not have to be changed, because it simply transparently passes input mask defined elsewhere and generates a set of items.

MSBuild concept of [items](https://learn.microsoft.com/en-us/visualstudio/msbuild/msbuild-items) is very powerful. It replaces all those silly iteration loops required by other scripting systems, as well as traversing any directories, recursive or not.

The real set of definitions comes from three common files. One of them, "Custom.props", is specific to the project and type of processing. The other two are applied to all projects in all downstream subdirectories: ["Directory.Build.props"](#code-directory-build-props) and 
["Directory.Build.targets"](#code-directory-build-targets).

This use of the shared properties and targets is analogous to the definitions for Microsoft toolchains: the common predefined sets of properties and targets come with MSBuild, Visual Studio, and other products. This way, more project files using common definitions, can be added.

### Properties

{id=code-directory-build-props}"Directory.Build.props":

```{lang=XML}
&lt;Project&gt;
    &lt;Import Project="Custom.props"/&gt;

    &lt;PropertyGroup&gt;

        &lt;OutputPath&gt;$(ProjectDir)output&lt;/OutputPath&gt;

        &lt;Tool&gt;ffmpeg&lt;/Tool&gt; &lt;!-- Linux --&gt;
        &lt;!-- For Windows: modify the path to access ffmpeg: --&gt;
        &lt;Tool
            Condition="$(OS.StartsWith('Windows'))"
            &gt;C:/app/Media/ffmpeg/bin/ffmpeg.exe&lt;/Tool&gt;

        &lt;Multitasking
            Condition="$(OS.StartsWith('Windows'))"
            &gt;start&lt;/Multitasking&gt;

        &lt;Continue&gt;%5C&lt;/Continue&gt; &lt;!-- backslash for Linux --&gt;
        &lt;Continue Condition="$(OS.StartsWith('Windows'))"&gt;^&lt;/Continue&gt;

    &lt;/PropertyGroup&gt;

&lt;/Project&gt;
```

### Targets 

{id=code-directory-build-targets}"Directory.Build.targets":

```{lang=XML}
&lt;Project&gt;

    &lt;Target Name="Transcode"&gt;

        &lt;PropertyGroup&gt;
            &lt;!-- MBSBuild item transform: --&gt;
            &lt;Commands&gt;@(InputFiles -&gt;
                    '$(Multitasking) $(Tool) -y -i $(Continue)
                    %(Identity) $(Scale) $(Continue)
                    $(Options) $(Continue)
                    $(OutputPath)%(Filename).$(OutputFileType)',
                ' %26 ')
            &lt;/Commands&gt;
        &lt;/PropertyGroup&gt;

        &lt;MakeDir Directories="$(OutputPath)" /&gt;
        &lt;Exec Command="$(Commands)"/&gt;

    &lt;/Target&gt;

&lt;/Project&gt;
```

The clause using "@" and "%" is a very interesting and powerful thing, MSBUilt items *transform*. Please see the Microsoft documentation on [MSBuild Transforms](https://learn.microsoft.com/en-us/visualstudio/msbuild/msbuild-transforms) for more information. In this clause, we transform the list of items into a list of commands executing FFmpeg.

Actually, the list of commands is concatenated using different ways of executing FFmpeg in parallel. It works differently in different systems. What is "%26"? This is the character "&". MSBuild does not allow direct use of this character, so it should be [escaped](https://learn.microsoft.com/en-us/visualstudio/msbuild/special-characters-to-escape) with a hexadecimal escape notation. For Linux, "&" between commands means the execution of them in parallel. For Windows, this character is also used, but it means consecutive execution of the commands. For execution in parallel on Windows, each command should be prepended with the command "start", which is defined as the property `Multitasking`.

There is another weird property `Continue`. It is defined to show the command in several lines, mostly for clarity and especially for the publication of the present article. It is a different character for Linux and Windows, "\" and "^" correspondently, and "\" is also the character to be escaped. Please see ["Directory.Build.props"](#code-directory-build-props).

The other input information is custom and is defined in a separate file "Custom.props", specific to a particular transcoding task. It supply the items and properties `@(InputFiles)`, $(Options), $(OutputPath) and, $(OutputFileType). So, finally, let's take a look at this file.

### Custom Properties

First of all, note the use of "**" wildcard. It extends the set of input files to the paths on all levels of nesting.

{id=code-custom-props}"Custom.props":

```{lang=XML}
&lt;Project&gt;
    &lt;PropertyGroup&gt;&lt;/PropertyGroup&gt;

    &lt;PropertyGroup&gt;
        &lt;InputMask&gt;../**/*.png&lt;/InputMask&gt;
        &lt;OutputFileType&gt;webp&lt;/OutputFileType&gt;
    &lt;/PropertyGroup&gt;

    &lt;PropertyGroup&gt;
        &lt;Scale&gt;-vf scale=256:-1&lt;/Scale&gt;
        &lt;Scale&gt;-vf scale=-1:128&lt;/Scale&gt;
        &lt;Scale&gt;&lt;/Scale&gt;
    &lt;/PropertyGroup&gt;

    &lt;PropertyGroup&gt;
        &lt;Options&gt;-lossless 0&lt;/Options&gt;
        &lt;Options&gt;-lossless 1&lt;/Options&gt;
        &lt;Options&gt;-quality 0&lt;/Options&gt;
        &lt;Options&gt;-quality 100&lt;/Options&gt;
        &lt;Options&gt;-preset none&lt;/Options&gt;
        &lt;Options&gt;-preset default&lt;/Options&gt;
        &lt;Options&gt;-preset picture&lt;/Options&gt;
        &lt;Options&gt;-preset photo&lt;/Options&gt;
        &lt;Options&gt;-preset drawing&lt;/Options&gt;
        &lt;Options&gt;-preset icon&lt;/Options&gt;
        &lt;Options&gt;-preset text&lt;/Options&gt;
        &lt;Options&gt;&lt;/Options&gt;
    &lt;/PropertyGroup&gt;

&lt;/Project&gt;
```

In these definitions, many different options are shown. As always, the property defined lower overwrites the properties defined above, so many definitions are redundant. They are placed here for convenience and self-documenting purposes. In this example, the properties `Scale` and `Options` are empty, but they can be changed by placing another property definition below the last line.

In the definition of `Scale`, the format `-vf scale=<width>:<height>` is used, and -1 means that width or height is calculated automatically, to make sure the *aspect ratio* remains the same.

## Compatibility and Testing

The solution is supposed to be compatible with all platforms where .NET is installed.

Tested thoroughly on Linux and Windows.

## Conclusions

The solution works smoothly on different platforms. It is very easy to upgrade to a more complicated solution. It shows the most ins and outs important for the development of a wide range of systems working with different input and output files without a rigid directory structure.
