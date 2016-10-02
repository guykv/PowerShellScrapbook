namespace Impersonation
{
    using System;
    using System.Runtime.ConstrainedExecution;
    using System.Runtime.InteropServices;
    using System.Security;
    using Microsoft.Win32.SafeHandles;

    public enum LogonType
    {
        Interactive = 2,   // LOGON32_LOGON_INTERACTIVE
        Network = 3,       // LOGON32_LOGON_NETWORK
        Batch = 4,         // LOGON32_LOGON_BATCH
        Service = 5,       // LOGON32_LOGON_SERVICE
        Unlock = 7,        // LOGON32_LOGON_UNLOCK
        Cleartext = 8,     // LOGON32_LOGON_NETWORK_CLEARTEXT
        NewCredentials = 9 // LOGON32_LOGON_NEW_CREDENTIALS
    }

    public class Impersonation
    {
        [DllImport("advapi32.dll", SetLastError = true, CharSet=CharSet.Unicode)]
        public static extern bool LogonUser(string lpszUsername, string lpszDomain, string lpszPassword, int dwLogonType, int dwLogonProvider, out SafeTokenHandle phToken);
    }

    public class SafeTokenHandle : SafeHandleZeroOrMinusOneIsInvalid
    {
        public SafeTokenHandle()
            : base(true)
        {
        }

        [DllImport("kernel32.dll", CharSet=CharSet.Auto)]
        [ReliabilityContract(Consistency.WillNotCorruptState, Cer.Success)]
        [SuppressUnmanagedCodeSecurity]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool CloseHandle(IntPtr handle);

        protected override bool ReleaseHandle()
        {
            return CloseHandle(handle);
        }
    }
}
