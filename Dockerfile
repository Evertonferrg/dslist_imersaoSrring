# Use uma imagem OpenJDK 21 slim para a etapa de build
FROM openjdk:21-jdk-slim AS build

# Defina o diretório de trabalho dentro do contêiner
WORKDIR /app

# Copie o wrapper Maven e pom.xml primeiro para aproveitar o cache de build do Docker
# Isso significa que se apenas o código-fonte mudar, as dependências Maven não serão re-baixadas
COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .

# Conceda permissões de execução ao script do Maven wrapper
RUN chmod +x ./mvnw

# Baixe as dependências (esta etapa falhará se mvnw não for executável ou pom.xml for inválido)
# Use 'dependency:resolve' apenas para baixar dependências sem construir o jar completo
RUN ./mvnw dependency:resolve

# Copie o restante do código-fonte da aplicação
COPY src src

# Empacote a aplicação
RUN ./mvnw -DskipTests package

# --- Etapa de Produção ---
# Use uma imagem JRE 21 leve e amplamente disponível para a etapa final (baseada em Ubuntu Jammy)
FROM eclipse-temurin:21-jre-jammy

# Defina o diretório de trabalho
WORKDIR /app

# Copie o JAR construído da etapa de build
COPY --from=build /app/target/*.jar app.jar

# Exponha a porta na qual seu aplicativo escuta (e.g., 8080 para Spring Boot)
EXPOSE 8080

# Execute a aplicação
ENTRYPOINT ["java", "-jar", "app.jar"]