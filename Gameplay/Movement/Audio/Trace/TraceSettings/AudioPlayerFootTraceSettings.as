UCLASS(NotBlueprintable)
class UAudioPlayerFootTraceSettings : UHazeAudioTraceSettings
{
	UPROPERTY(EditDefaultsOnly, Meta = (ComposedStruct))
	FAudioFootTraceSettings Left;
	default Left.SocketName = MovementAudio::Player::LeftFootBoneName;

	UPROPERTY(EditDefaultsOnly, Meta = (ComposedStruct))
	FAudioFootTraceSettings Right;
	default Right.SocketName = MovementAudio::Player::RightFootBoneName;

	UFUNCTION()
	TArray<FString> GetFootSocketNames() const
	{
		TArray<FString> SocketNames;	
		
		SocketNames.Add("LeftFootAudioTrace");
		SocketNames.Add("LeftFootSocket");
		SocketNames.Add("LeftFootToeAudioTrace");

		SocketNames.Add("RightFootAudioTrace");
		SocketNames.Add("RightFootSocket");
		SocketNames.Add("RightFootToeAudioTrace");		

		return SocketNames;
	}

}