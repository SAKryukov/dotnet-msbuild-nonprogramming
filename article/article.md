@numbering {
    enable: false
}

{title}MSBuild for Programming and Non-Programming Chores

[*Sergey A Kryukov*](https://www.SAKryukov.org)

Using MSBuild for Programming and Non-Programming Chores

Using MSBuild for Programming and Non-Programming Chores

<!-- https://www.codeproject.com/Articles/? -->

<!-- copy to CodeProject from here ------------------------------------------->


## Contents{no-toc}

@toc

## Introduction

MSBuild 

//SA???

## Code Sample

I am going to 

## Why .NET?

MSBuild can be invoked in several ways. First of all, the command is "MSBuild". MSBuild is also used for building of .NET projects and solutions, and then it is "dotnet build".

But I recommend using "dotnet msbuild". It is clear why "dotnet build" is not suitable for non-.NET solutions, this command does not even have the "target" option. But why "dotnet msbuild" and not "MSBuild"?

The first reason is the deployment: I don't know where your MSBuild instance is located. Developers often have several MSBuild instances installed at the same time, different versions of them. As to .NET, it is usually installed to have the application path "dotnet" accessible everywhere, and it knows the version of MSBuild supplied with it, and will launch the most appropriate version.

There is another, more subtle reason: with "dotnet msbuild" you can use very convenient .NET API functions in MSBuild property definitions. For the detailed description of this possibility, please see Microsoft documentation on [property functions](https://learn.microsoft.com/en-us/visualstudio/msbuild/property-functions)

"run.cmd":
```
dotnet msbuild a.project -t:Transcode
```

This simple command line is designed to be usable for Windows and other systems. For Linux, is should also be made executable before using it:

```
chmod -x run.cmd
```

## Implementation

"a.project":

```{lang=XML}
&lt;Project Sdk="Microsoft.NET.Sdk"&gt;

&lt;ItemGroup&gt;
    &lt;InputFiles Include="$(InputMask)"/&gt;
&lt;/ItemGroup&gt;

&lt;/Project&gt;
```

"Custom.props":

```{lang=XML}
&lt;Project&gt;
    &lt;PropertyGroup&gt;&lt;/PropertyGroup&gt;

    &lt;PropertyGroup&gt;
        &lt;InputMask&gt;../**/*.png&lt;/InputMask&gt;
        &lt;OutputFileType&gt;webp&lt;/OutputFileType&gt;
        &lt;Scale&gt;-vf scale=256:-1&lt;/Scale&gt;
        &lt;Scale&gt;-vf scale=-1:128&lt;/Scale&gt;
        &lt;Scale&gt;&lt;/Scale&gt;
    &lt;/PropertyGroup&gt;

&lt;/Project&gt;
```

"Directory.Build.props":

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

"Directory.Build.targets":

```{lang=XML}
&lt;Project&gt;

    &lt;Target Name="Transcode"&gt;

        &lt;PropertyGroup&gt;
            &lt;!-- MBSBuild item transform: --&gt;
            &lt;Commands&gt;@(InputFiles -&gt;
                    '$(Multitasking) $(Tool) -y -i $(Continue)
                    %(Identity) $(Scale)  $(Continue)
                    $(OutputPath)%(Filename).$(OutputFileType)',
                ' %26 ')
            &lt;/Commands&gt;
        &lt;/PropertyGroup&gt;

        &lt;MakeDir Directories="$(OutputPath)" /&gt;
        &lt;Exec Command="$(Commands)"/&gt;

    &lt;/Target&gt;

&lt;/Project&gt;
```
