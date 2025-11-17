plugins {
    id("java")
    id("war")
}

group = "ru.mihozhereb"
version = "1.0"

repositories {
    mavenCentral()
}

dependencies {
    compileOnly("jakarta.platform:jakarta.jakartaee-web-api:11.0.0")
    implementation("org.primefaces:primefaces:15.0.10:jakarta")

    implementation("org.postgresql:postgresql:42.7.8")

    implementation("com.google.code.gson:gson:2.11.0")

    testImplementation(platform("org.junit:junit-bom:5.10.0"))
    testImplementation("org.junit.jupiter:junit-jupiter")
}

tasks.test {
    useJUnitPlatform()
}

tasks.war {
    archiveFileName.set("web-lab-3.war")
    webAppDirectory.set(file("src/main/webapp"))
}