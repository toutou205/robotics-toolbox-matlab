%CodeGenerator.genmfuncoriolis  Generates M-functions for the Coriolis matrix.
%
% cGen.genmfuncoriolis()
%
% Notes::
% - Is called by CodeGenerator.gencoriolis if cGen has active flag genmfun
% - The Coriolis matrix is stored row by row to avoid memory issues.
% - The generated M-function recombines the individual M-functions for each row.
% - Access to generated functions is provided via 
% subclass of SerialLink stored in cGen.robjpath
%
% Authors::
%  J�rn Malzahn
%  2012 RST, Technische Universit�t Dortmund, Germany
%  http://www.rst.e-technik.tu-dortmund.de
%
% See also CodeGenerator, gencoriolis, geninertia

% Copyright (C) 1993-2012, by Peter I. Corke
%
% This file is part of The Robotics Toolbox for Matlab (RTB).
%
% RTB is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% RTB is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU Lesser General Public License for more details.
%
% You should have received a copy of the GNU Leser General Public License
% along with RTB.  If not, see <http://www.gnu.org/licenses/>.
%
% http://www.petercorke.com

function [ ] = genmfuncoriolis( CGen )

%% Does robot class exist?
if ~exist(fullfile(CGen.robjpath,[CGen.getrobfname,'.m']),'file')
    CGen.logmsg([datestr(now),'\tCreating ',CGen.getrobfname,' m-constructor ']);
    CGen.createmconstructor;
    CGen.logmsg('\t%s\n',' done!');
end

%%
CGen.logmsg([datestr(now),'\tGenerating m-function for the Coriolis matrix row' ]);

[q, qd] = CGen.rob.gencoords;
nJoints = CGen.rob.n;

for kJoints = 1:nJoints
    CGen.logmsg(' %s ',num2str(kJoints));
    symname = ['coriolis_row_',num2str(kJoints)];
    fname = fullfile(CGen.sympath,[symname,'.mat']);
    
    if exist(fname,'file')
        tmpStruct = load(fname);
    else
        error ('genmfuncoriolis:SymbolicsNotFound','Save symbolic expressions to disk first!')
    end
    
    funfilename = fullfile(CGen.robjpath,[symname,'.m']);
    
    matlabFunction(tmpStruct.(symname),'file',funfilename,...              % generate function m-file
        'outputs', {'Crow'},...
        'vars', {'rob',q,qd});
    hStruct = createHeaderStructRow(CGen.rob,kJoints,symname);                 % replace autogenerated function header
    replaceheader(CGen,hStruct,funfilename);
    
    
end
CGen.logmsg('\t%s\n',' done!');


CGen.logmsg([datestr(now),'\tGenerating full Coriolis matrix m-function: ']);
    
    funfilename = fullfile(CGen.robjpath,'coriolis.m');
    hStruct = createHeaderStructFull(CGen.rob,funfilename);
    
    fid = fopen(funfilename,'w+');
    
    fprintf(fid, '%s\n', ['function C = coriolis(rob,q,qd)']);                 % Function definition
    fprintf(fid, '%s\n',constructheaderstring(CGen,hStruct));                   % Header
   
    fprintf(fid, '%s \n', 'C = zeros(length(q));');                        % Code
    for iJoints = 1:nJoints
        funCall = ['C(',num2str(iJoints),',:) = ','rob.coriolis_row_',num2str(iJoints),'(q,qd);'];
        fprintf(fid, '%s \n', funCall);
    end
    
    fclose(fid);
    
    CGen.logmsg('\t%s\n',' done!');           
end

function hStruct = createHeaderStructRow(rob,curJointIdx,fName)
[~,hStruct.funName] = fileparts(fName);
hStruct.shortDescription = ['Computation of the robot specific Coriolis matrix row for joint ', num2str(curJointIdx), ' of ',num2str(rob.n),'.'];
hStruct.calls = {['Crow = ',hStruct.funName,'(rob,q,qd)'],...
    ['Crow = rob.',hStruct.funName,'(q,qd)']};
hStruct.detailedDescription = {'Given a full set of joint variables and their first order temporal derivatives this function computes the',...
                               ['Coriolis matrix row number ', num2str(curJointIdx),' of ',num2str(rob.n),' for ',rob.name,'.']};
hStruct.inputs = { ['rob: robot object of ', rob.name, ' specific class'],...
                   ['q:  ',int2str(rob.n),'-element vector of generalized'],...
                   '     coordinates';
                   ['qd:  ',int2str(rob.n),'-element vector of generalized'],...
                   '     velocities', ...
                   'Angles have to be given in radians!'};
hStruct.outputs = {['Crow:  [1x',int2str(rob.n),'] row of the robot Coriolis matrix']};
hStruct.references = {'1) Robot Modeling and Control - Spong, Hutchinson, Vidyasagar',...
    '2) Modelling and Control of Robot Manipulators - Sciavicco, Siciliano',...
    '3) Introduction to Robotics, Mechanics and Control - Craig',...
    '4) Modeling, Identification & Control of Robots - Khalil & Dombre'};
hStruct.authors = {'This is an autogenerated function.',...
    'Code generator written by:',...
    'J�rn Malzahn',...
    '2012 RST, Technische Universit�t Dortmund, Germany',...
    'http://www.rst.e-technik.tu-dortmund.de'};
hStruct.seeAlso = {'coriolis'};
end

function hStruct = createHeaderStructFull(rob,fName)
[~,hStruct.funName] = fileparts(fName);
hStruct.shortDescription = ['Coriolis matrix for the ',rob.name,' arm'];
hStruct.calls = {['Crow = ',hStruct.funName,'(rob,q,qd)'],...
    ['Crow = rob.',hStruct.funName,'(q,qd)']};
hStruct.detailedDescription = {'Given a full set of joint variables and their first order temporal derivatives the function computes the',...
                               'Coriolis matrix of the robot.'};
hStruct.inputs = { ['rob: robot object of ', rob.name, ' specific class'],...
                   ['q:  ',int2str(rob.n),'-element vector of generalized'],...
                   '     coordinates';
                   ['qd:  ',int2str(rob.n),'-element vector of generalized'],...
                   '     velocities', ...
                   'Angles have to be given in radians!'};
hStruct.outputs = {['C:  [',int2str(rob.n),'x',int2str(rob.n),'] Coriolis matrix']};
hStruct.references = {'1) Robot Modeling and Control - Spong, Hutchinson, Vidyasagar',...
    '2) Modelling and Control of Robot Manipulators - Sciavicco, Siciliano',...
    '3) Introduction to Robotics, Mechanics and Control - Craig',...
    '4) Modeling, Identification & Control of Robots - Khalil & Dombre'};
hStruct.authors = {'This is an autogenerated function!',...
    'Code generator written by:',...
    'J�rn Malzahn',...
    '2012 RST, Technische Universit�t Dortmund, Germany',...
    'http://www.rst.e-technik.tu-dortmund.de'};
hStruct.seeAlso = {'inertia'};
end