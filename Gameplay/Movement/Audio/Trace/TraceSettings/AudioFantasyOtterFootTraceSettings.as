UCLASS(NotBlueprintable)
class UAudioFantasyOtterFootTraceSettings : UHazeAudioTraceSettings
{
	UPROPERTY(EditDefaultsOnly, Meta = (ComposedStruct))
	FAudioFootTraceSettings LeftFoot;
	default LeftFoot.SocketName = MovementAudio::FantasyOtter::LeftFootSocketName;
	default LeftFoot.SphereTraceRadius = 15.0;

	UPROPERTY(EditDefaultsOnly, Meta = (ComposedStruct))
	FAudioFootTraceSettings RightFoot;	
	default RightFoot.SocketName = MovementAudio::FantasyOtter::RightFootSocketName;
	default RightFoot.SphereTraceRadius = 15.0;

	UPROPERTY(EditDefaultsOnly, Meta = (ComposedStruct))
	FAudioFootTraceSettings LeftHand;	
	default LeftHand.SocketName = MovementAudio::FantasyOtter::LeftHandSocketName;
	default LeftHand.SphereTraceRadius = 15.0;

	UPROPERTY(EditDefaultsOnly, Meta = (ComposedStruct))
	FAudioFootTraceSettings RightHand;	
	default RightHand.SocketName = MovementAudio::FantasyOtter::RightHandSocketName;
	default RightHand.SphereTraceRadius = 15.0;

	FAudioFootTraceSettings GetTraceSettings(const EFantasyOtterFootType FootType)
	{
		switch(FootType)
		{
			case(EFantasyOtterFootType::LeftFoot): return LeftFoot;
			case(EFantasyOtterFootType::RightFoot): return RightFoot;
			case(EFantasyOtterFootType::LeftHand): return LeftHand;
			case(EFantasyOtterFootType::RightHand): return RightHand;
			default: break;
		}

		return FAudioFootTraceSettings();
	}

	UFUNCTION()
	TArray<FString> GetFootSocketNames() const
	{
		TArray<FString> SocketNames;		
		
		SocketNames.Add(MovementAudio::FantasyOtter::LeftFootSocketName.ToString());
		SocketNames.Add(MovementAudio::FantasyOtter::RightFootSocketName.ToString());
		SocketNames.Add(MovementAudio::FantasyOtter::LeftHandSocketName.ToString());
		SocketNames.Add(MovementAudio::FantasyOtter::RightHandSocketName.ToString());	

		return SocketNames;
	}
}