document.getElementById("kc-register-form").addEventListener("submit", function (e) {
    const p1 = document.getElementById("password").value;
    const p2 = document.getElementById("passwordConfirm").value;

    if (p1 !== p2) {
        e.preventDefault();
        alert("Passwords do not match");
    }
});