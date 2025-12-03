namespace GiantsAudio
{
	const FString SocketNames = 
"""
None,
LeftFootAudio, 
LeftToeAudio,
LeftKneeAudio,
LeftHipAudio,
LeftHandAudio,
LeftElbowAudio,
LeftShoulderAudio,
RightFootAudio,
RightToeAudio,
RightKneeAudio,
RightHipAudio,
RightHandAudio,
RightElbowAudio,
RightShoulderAudio,
NavelAudio,
AssAudio,
ChestAudio,
BackAudio,
MouthAudio,
NoseAudio,
HeadAudio
""";

#if EDITOR
	TArray<FName> GetSocketNames()
	{
		TArray<FString> OutStrings;
		TArray<FString> Delimiters;
		Delimiters.Add(",");
		SocketNames.ParseIntoArray(OutStrings, Delimiters);

		TArray<FName> SocketNames;
		for(auto& StringName : OutStrings)
		{
			SocketNames.Add(FName(StringName));
		}

		return SocketNames;
	}
#endif
}