﻿using Mono.Cecil;
using Mono.Cecil.Cil;
using MonoMod.Utils;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Drawing;
using System.Globalization;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Net;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace Olympus {
    public unsafe class CmdAhornRunJuliaTask : Cmd<string, bool?, IEnumerator> {
        public override bool LogRun => false;
        public override IEnumerator Run(string script, bool? localDepot) {
            yield return AhornHelper.GetJuliaOutput(script, localDepot);
        }
    }
}
