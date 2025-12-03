class UAudioTundraTreeGuardianFootTraceSettings : UHazeAudioTraceSettings
{
	UPROPERTY(EditDefaultsOnly, Meta = (ComposedStruct))
	FAudioFootTraceSettings LeftFoot;
	default LeftFoot.SocketName = MovementAudio::TundraTreeGuardian::LeftFootSocketName;
	default LeftFoot.SphereTraceRadius = 15.0;

	UPROPERTY(EditDefaultsOnly, Meta = (ComposedStruct))
	FAudioFootTraceSettings RightFoot;
	default LeftFoot.SocketName = MovementAudio::TundraTreeGuardian::RightFootSocketName;
	default RightFoot.SphereTraceRadius = 15.0;

	UPROPERTY(EditDefaultsOnly, Meta = (ComposedStruct))
	FAudioFootTraceSettings LeftHand;
	default LeftFoot.SocketName = MovementAudio::TundraTreeGuardian::LeftHandSocketName;
	default LeftHand.SphereTraceRadius = 15.0;

	UPROPERTY(EditDefaultsOnly, Meta = (ComposedStruct))
	FAudioFootTraceSettings RightHand;
	default LeftFoot.SocketName = MovementAudio::TundraTreeGuardian::RightHandSocketName;
	default RightHand.SphereTraceRadius = 15.0;

	FAudioFootTraceSettings GetTraceSettings(const ETundraTreeGuardianFootType FootType)
	{
		switch(FootType)
		{
			case(ETundraTreeGuardianFootType::LeftFoot): return LeftFoot;
			case(ETundraTreeGuardianFootType::RightFoot): return RightFoot;
			case(ETundraTreeGuardianFootType::LeftHand): return LeftHand;
			case(ETundraTreeGuardianFootType::RightHand): return RightHand;
			default: break;
		}

		return FAudioFootTraceSettings();
	}
	
}