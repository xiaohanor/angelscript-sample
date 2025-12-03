UCLASS(NotBlueprintable)
class UAudioTundraMonkeyFootTraceSettings : UHazeAudioTraceSettings
{
	UPROPERTY(EditDefaultsOnly, Meta = (ComposedStruct))
	FAudioFootTraceSettings LeftFoot;
	default LeftFoot.SocketName = MovementAudio::Dragons::FrontLeftFootSocketName;
	default LeftFoot.SphereTraceRadius = 15.0;

	UPROPERTY(EditDefaultsOnly, Meta = (ComposedStruct))
	FAudioFootTraceSettings RightFoot;	
	default RightFoot.SocketName = MovementAudio::Dragons::FrontRightFootSocketName;
	default RightFoot.SphereTraceRadius = 15.0;

	UPROPERTY(EditDefaultsOnly, Meta = (ComposedStruct))
	FAudioFootTraceSettings LeftHand;	
	default LeftHand.SocketName = MovementAudio::Dragons::BackLeftFootTraceSocketName;
	default LeftHand.SphereTraceRadius = 15.0;

	UPROPERTY(EditDefaultsOnly, Meta = (ComposedStruct))
	FAudioFootTraceSettings RightHand;	
	default RightHand.SocketName = MovementAudio::Dragons::BackRightFootTraceSocketName;
	default RightHand.SphereTraceRadius = 15.0;

	UPROPERTY(EditDefaultsOnly, Meta = (ComposedStruct))
	FAudioFootTraceSettings JumpAndLand;
	default JumpAndLand.SocketName = MovementAudio::Dragons::BackLeftFootTraceSocketName;
	default JumpAndLand.SphereTraceRadius = 15.0 + 60;

	FAudioFootTraceSettings GetTraceSettings(const ETundraMonkeyFootType FootType)
	{
		switch(FootType)
		{
			case(ETundraMonkeyFootType::LeftFoot): return LeftFoot;
			case(ETundraMonkeyFootType::RightFoot): return RightFoot;
			case(ETundraMonkeyFootType::LeftHand): return LeftHand;
			case(ETundraMonkeyFootType::RightHand): return RightHand;
			case(ETundraMonkeyFootType::Jump): return JumpAndLand;
			default: break;
		}

		return FAudioFootTraceSettings();
	}

	UFUNCTION()
	TArray<FString> GetFootSocketNames() const
	{
		TArray<FString> SocketNames;		
		
		SocketNames.Add(MovementAudio::TundraMonkey::LeftFootSocketName.ToString());
		SocketNames.Add(MovementAudio::TundraMonkey::RightFootSocketName.ToString());
		SocketNames.Add(MovementAudio::TundraMonkey::LeftHandSocketName.ToString());
		SocketNames.Add(MovementAudio::TundraMonkey::RightHandSocketName.ToString());	

		return SocketNames;
	}
}