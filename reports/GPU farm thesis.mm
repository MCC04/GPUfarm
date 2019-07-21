<map version="0.9.0">
<!-- To view this file, download free mind mapping software FreeMind from http://freemind.sourceforge.net -->
<node CREATED="1560452078682" ID="ID_839677197" MODIFIED="1563181485801" TEXT="GPU farm thesis">
<icon BUILTIN="edit"/>
<node CREATED="1560452188721" ID="ID_265984272" MODIFIED="1563181446889" POSITION="right" TEXT="Introduction">
<icon BUILTIN="full-1"/>
<node CREATED="1560452398852" ID="ID_1579447563" MODIFIED="1560452406138" TEXT="Goals"/>
<node CREATED="1560455175350" ID="ID_928678996" MODIFIED="1560455182192" TEXT="Expectation"/>
<node CREATED="1560452417938" ID="ID_111952887" MODIFIED="1560452428831" TEXT="Results"/>
<node CREATED="1560452406878" ID="ID_628701279" MODIFIED="1560452434893" TEXT="Tools"/>
<node CREATED="1560452515309" ID="ID_1157401244" MODIFIED="1560452532448" TEXT="Following chapters overview"/>
</node>
<node CREATED="1560452194577" FOLDED="true" ID="ID_1200288506" MODIFIED="1563181449560" POSITION="right" TEXT="Tools">
<icon BUILTIN="full-2"/>
<node CREATED="1560452541051" ID="ID_1116934850" MODIFIED="1560452563384" TEXT="CUDA 10.0">
<node CREATED="1563180618035" ID="ID_134255605" MODIFIED="1563180628101" TEXT="CUDA Toolkit">
<node CREATED="1563180818249" ID="ID_1073091821" MODIFIED="1563180823193" TEXT="nvidia-smi"/>
<node CREATED="1563180823834" ID="ID_1897649215" MODIFIED="1563180846513" TEXT="CUDA Occupancy spreadsheet"/>
</node>
</node>
<node CREATED="1560452564126" ID="ID_1936632397" MODIFIED="1560452577477" TEXT="nvprof/nSight"/>
<node CREATED="1560452577989" ID="ID_775419898" MODIFIED="1560452595807" TEXT="C++ (Visual Studio)"/>
<node CREATED="1560452610839" ID="ID_703106802" MODIFIED="1560452630409" TEXT="Python"/>
</node>
<node CREATED="1560452238525" FOLDED="true" ID="ID_1132952857" MODIFIED="1563181453305" POSITION="right" TEXT="Project Logic">
<icon BUILTIN="full-3"/>
<attribute NAME="About 20 pages" VALUE=""/>
<node CREATED="1560452669302" ID="ID_975645035" MODIFIED="1563180806124" TEXT="Farm in GPU">
<node CREATED="1560452687712" ID="ID_367070538" MODIFIED="1560452789871" TEXT="Stream simulator "/>
<node CREATED="1560452767333" ID="ID_1788727090" MODIFIED="1560452876529" TEXT="Data Transfer and Kernel">
<attribute NAME="Streams" VALUE=""/>
</node>
<node CREATED="1560452811659" ID="ID_357648853" MODIFIED="1560452832207" TEXT="Data gathering and Measures"/>
</node>
</node>
<node CREATED="1560452289442" FOLDED="true" ID="ID_1138853824" MODIFIED="1563181459864" POSITION="right" TEXT="Implementation">
<icon BUILTIN="full-4"/>
<node CREATED="1560453107667" ID="ID_40188319" MODIFIED="1563180698350" TEXT="GPU farm">
<node CREATED="1560452898255" ID="ID_1128308424" MODIFIED="1563180684067" TEXT="Stream Simulator">
<node CREATED="1563180752115" ID="ID_1526581992" MODIFIED="1563180773663" TEXT="Very small chunks"/>
<node CREATED="1563180774585" ID="ID_1864682530" MODIFIED="1563180781736" TEXT="Occupancy"/>
<node CREATED="1563180782153" ID="ID_1040452401" MODIFIED="1563180793825" TEXT="CUDA streams"/>
</node>
<node CREATED="1560453068580" FOLDED="true" ID="ID_938227987" MODIFIED="1560453813506" TEXT="Data Transfer">
<node CREATED="1560453336083" ID="ID_911193034" MODIFIED="1560453349903" TEXT="Streams"/>
<node CREATED="1560453350547" ID="ID_986758885" MODIFIED="1560453354628" TEXT="Overlapping"/>
<node CREATED="1560453354837" ID="ID_954829708" MODIFIED="1560453357899" TEXT="Pinned"/>
</node>
<node CREATED="1560453090860" FOLDED="true" ID="ID_1047177539" MODIFIED="1560453812842" TEXT="Kernels">
<node CREATED="1560453471280" ID="ID_1575139999" MODIFIED="1560453488129" TEXT="Cosine (M times)"/>
<node CREATED="1560453488612" ID="ID_1794315438" MODIFIED="1560453517497" TEXT="Square MatMul">
<attribute NAME="NotOptimized(shared)" VALUE=""/>
</node>
</node>
<node CREATED="1560453096462" FOLDED="true" ID="ID_1206398821" MODIFIED="1560453815697" TEXT="Data gathering">
<node CREATED="1560453765278" ID="ID_344416618" MODIFIED="1560453808811" TEXT="Re-build chunks"/>
</node>
<node CREATED="1560453104380" FOLDED="true" ID="ID_1932131510" MODIFIED="1560453814513" TEXT="Measures">
<node CREATED="1560453739670" ID="ID_895414237" MODIFIED="1560453744850" TEXT="Event Measures"/>
<node CREATED="1560453745302" ID="ID_282370870" MODIFIED="1560453752443" TEXT="Chrono Host measures"/>
</node>
</node>
<node CREATED="1563180700676" ID="ID_307885020" MODIFIED="1563180726935" TEXT="GPU hybrid stream/data">
<node CREATED="1560453548052" ID="ID_337400005" MODIFIED="1560453567230" TEXT="Random N number generator"/>
<node CREATED="1560453387738" ID="ID_1537235963" MODIFIED="1560453445469" TEXT="Accumulate in chunks"/>
</node>
<node CREATED="1560453144091" FOLDED="true" ID="ID_1685091860" MODIFIED="1563181412765" TEXT="GPU data parallel">
<node CREATED="1560453229635" ID="ID_1200453913" MODIFIED="1560453247284" TEXT="Big Data Structure"/>
<node CREATED="1560453248122" ID="ID_1855774160" MODIFIED="1560453267275" TEXT="Single huge Data Transfer"/>
<node CREATED="1560453282164" ID="ID_33755018" MODIFIED="1560453300369" TEXT="Single huge Kernel"/>
</node>
<node CREATED="1560453601789" FOLDED="true" ID="ID_292594994" MODIFIED="1560453825867" TEXT="CPU/GPU mix">
<node CREATED="1560453613903" ID="ID_991071073" MODIFIED="1560453637841" TEXT="Stream simulator"/>
<node CREATED="1560453638672" ID="ID_1356729469" MODIFIED="1560453702819" TEXT="Assign CPU chunk">
<attribute NAME="P" VALUE=""/>
</node>
<node CREATED="1560453672405" ID="ID_809883202" MODIFIED="1560453707524" TEXT="Assign GPU chunk">
<attribute NAME="Q" VALUE=""/>
</node>
<node CREATED="1560453685433" ID="ID_1505752959" MODIFIED="1560453730349" TEXT="Re-compute P and Q"/>
</node>
</node>
<node CREATED="1560452297055" FOLDED="true" ID="ID_1511496910" MODIFIED="1563181464408" POSITION="right" TEXT="Experiments">
<icon BUILTIN="full-5"/>
<node CREATED="1560454760472" ID="ID_1784916804" MODIFIED="1560454900928" TEXT="General description"/>
<node CREATED="1560455026088" ID="ID_1480651847" MODIFIED="1560455077387" TEXT="What &amp; How">
<node CREATED="1560454596020" FOLDED="true" ID="ID_229549826" MODIFIED="1560455069250" TEXT="Farm mode">
<node CREATED="1560454157025" ID="ID_1260414925" MODIFIED="1560454579327" TEXT="&lt;&lt;&lt;56*k, blockDim&gt;&gt;&gt;"/>
<node CREATED="1560454549613" ID="ID_490110063" MODIFIED="1560454565869" TEXT="&lt;&lt;&lt;1, blockDim&gt;&gt;&gt;"/>
<node CREATED="1560454920740" ID="ID_699718819" MODIFIED="1560454927128" TEXT="Results"/>
<node CREATED="1560454927610" ID="ID_381389803" MODIFIED="1560454958785" TEXT="Comparison LOW/HIGH mesures"/>
</node>
<node CREATED="1560454604341" FOLDED="true" ID="ID_697057365" MODIFIED="1560455071770" TEXT="Data Parallel mode">
<node CREATED="1560454631829" ID="ID_1642153846" MODIFIED="1560454675556" TEXT="&lt;&lt;&lt;(N/blockSize), blockSize&gt;&gt;&gt;"/>
<node CREATED="1560454975593" ID="ID_757570664" MODIFIED="1560454978615" TEXT="Results"/>
<node CREATED="1560454978838" ID="ID_25365780" MODIFIED="1560455000413" TEXT="Comparison Farm/Data Par"/>
</node>
</node>
<node CREATED="1560455078654" ID="ID_495724471" MODIFIED="1560455094537" TEXT="Some Plots"/>
<node CREATED="1560455010318" ID="ID_1966421460" MODIFIED="1560455016782" TEXT="Summary"/>
</node>
<node CREATED="1560452302982" FOLDED="true" ID="ID_1470917552" MODIFIED="1563181467257" POSITION="right" TEXT="Conclusions">
<icon BUILTIN="full-6"/>
<node CREATED="1560454689582" ID="ID_1319250957" MODIFIED="1560454716593" TEXT="Introduction (brief)"/>
<node CREATED="1560454718426" ID="ID_1899365745" MODIFIED="1560455119306" TEXT="Tools (brief)"/>
<node CREATED="1560455119704" ID="ID_1549127971" MODIFIED="1560455132309" TEXT="Logic and Implementation (brief)"/>
<node CREATED="1560455132691" ID="ID_1158526735" MODIFIED="1560455141058" TEXT="Experiments"/>
<node CREATED="1560455141425" ID="ID_1444919187" MODIFIED="1560455146554" TEXT="Comments on results"/>
<node CREATED="1560455146846" ID="ID_1131094756" MODIFIED="1560455195130" TEXT="Future works"/>
</node>
</node>
</map>
