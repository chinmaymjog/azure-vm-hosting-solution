import org.jenkinsci.plugins.scriptsecurity.scripts.ScriptApproval

def scriptApproval = ScriptApproval.get()
def signatures = [
    "new java.io.File java.lang.String",
    "method java.io.File exists",
    "new groovy.json.JsonSlurper",
    "method groovy.json.JsonSlurper parse java.io.File"
]

signatures.each { sig ->
    scriptApproval.approveSignature(sig)
}
scriptApproval.save()
