function getMessageType(message) {
  if (message.fatal || message.severity === 2) {
    return "error";
  }
  return "warning";
}

module.exports = function (results) {
  let output = "";

  results.forEach((result) => {
    const messages = result.messages;

    messages.forEach((message) => {
      output += result.filePath;
      output += `(${message.line || 0}`;
      output += message.column ? `,${message.column}` : "";
      output += `): ${getMessageType(message)}`;
      output += message.ruleId ? ` ${message.ruleId}` : "";
      output += ` : ${message.message}`;
      output += "\n";
    });
  });

  return output;
};
