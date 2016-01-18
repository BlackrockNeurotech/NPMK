function CCF = ParseCCF()

[fileName pathName] = getFile('*.ccf', 'Choose a CCF file...');
OBJ = xmlread(fullfile(pathName,fileName))
removeIndentNodes(OBJ.getChildNodes);
CCF = parseChildNodes(OBJ);


%function children = parseChildNodes(OBJ)
function children = parseChildNodes(theNode)
% Recurse over node children.
children = [];
if theNode.hasChildNodes
   childNodes = theNode.getChildNodes;
   numChildNodes = childNodes.getLength;
   allocCell = cell(1, numChildNodes);

   children = struct(             ...
      'Name', allocCell, 'Attributes', allocCell,    ...
      'Data', allocCell, 'Children', allocCell);

    for count = 1:numChildNodes
        theChild = childNodes.item(count-1);
        children(count) = makeStructFromNode(theChild);
    end
end


%function nodeStruct - makeStructFromNode(OBJ)
function nodeStruct = makeStructFromNode(theNode)
nodeStruct = struct(...
    'Name',char(theNode.getNodeName),...
    'Attributes', parseAttributes(theNode),...
    'Data','',...
    'Children', parseChildNodes(theNode));


if any(strcmp(methods(theNode), 'getData'))
    nodeStruct.Data = char(theNode.getData);
else
    nodeStruct.Data = '';
end




function attributes = parseAttributes(theNode)
% Create attributes structure.

attributes = [];
if theNode.hasAttributes
   theAttributes = theNode.getAttributes;
   numAttributes = theAttributes.getLength;
   allocCell = cell(1, numAttributes);
   attributes = struct('Name', allocCell, 'Value', ...
                       allocCell);

   for count = 1:numAttributes
      attrib = theAttributes.item(count-1);
      attributes(count).Name = char(attrib.getName);
      attributes(count).Value = char(attrib.getValue);
   end
end


function removeIndentNodes( childNodes )

numNodes = childNodes.getLength;
remList = [];
for i = numNodes:-1:1
   theChild = childNodes.item(i-1);
   if (theChild.hasChildNodes)
      removeIndentNodes(theChild.getChildNodes);
   else
      if ( theChild.getNodeType == theChild.TEXT_NODE && ...
           ~isempty(char(theChild.getData()))         && ...
           all(isspace(char(theChild.getData()))))
         remList(end+1) = i-1; % java indexing
      end
   end
end
for i = 1:length(remList)
   childNodes.removeChild(childNodes.item(remList(i)));
end



