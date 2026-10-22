When writing code with tailwind do the following:

Add descriptive, unique id attributes to major page sections and important unique interactive elements where appropriate.
Add data-component="ComponentName" to important component root elements.
Add data-element="descriptive-name" to important child elements that would otherwise be difficult to identify in Inspect Element.
Use consistent kebab-case naming for IDs and data-element values. Use consistent component names for data-component.
Do not add IDs to every element. Avoid duplicate IDs, unnecessary attributes, and redundant labels.
Do not use IDs as Tailwind styling hooks. Keep className responsible for styling.
Do not modify business logic, accessibility attributes, form behavior, or API integrations.
For repeated components such as product cards, use appropriate shared data-component labels rather than duplicate IDs.
Review the changes for duplicate IDs, unintended UI changes, and broken functionality.

First inspect the project structure and establish a consistent naming convention. Then implement the changes incrementally and summarize which files were modified.