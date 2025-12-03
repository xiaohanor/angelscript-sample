class UAnimNotify_TundraFairyFootstep : UAnimNotify_HazeSoundDefTrigger
{
	default SoundDefClass = UGameplay_Character_Creature_Player_Tundra_Fairy_SoundDef;

	UGameplay_Character_Creature_Player_Tundra_Fairy_SoundDef GetFairySoundDef() const property
	{
		return Cast<UGameplay_Character_Creature_Player_Tundra_Fairy_SoundDef>(SoundDef);
	}

	UPROPERTY(EditInstanceOnly)
	EFootType Foot = EFootType::None;

	const FName PLAYER_FOOT_GROUP = n"Player_Foot";

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				FAnimNotifyEventReference EventReference) const
	{
		if(Foot == EFootType::None)
			return false;

		auto Fairy = Cast<ATundraPlayerFairyActor>(MeshComp.Owner);

		if(Fairy == nullptr || FairySoundDef == nullptr)
			return false;

		UPlayerFootstepTraceComponent TraceComp = UPlayerFootstepTraceComponent::Get(Fairy.Player);	
		UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(Fairy.Player);
		UPlayerAudioMaterialComponent MaterialComp = UPlayerAudioMaterialComponent::Get(Fairy.Player);

		FPlayerFootstepTraceData& TraceData = TraceComp.GetTraceData(Foot);	

		// Reset performed-flag
		TraceData.Trace.bPerformed = false;
		TraceData.Trace.bGrounded = false;
																					// Move up start position of trace slighlty so that we don't miss mesh layers because of Fairy scaling
		TraceData.Start = MeshComp.GetSocketLocation(TraceData.Settings.SocketName) - (FVector::UpVector * -10);

		const float TraceLength = GetScaledTraceLength(MoveComp.Velocity.Size(), TraceData);

		TraceData.End = GetTraceFrameEndPos(MeshComp, TraceData, TraceLength);

		if(!TraceComp.PerformFootTrace_Sphere(TraceData, TraceData.Settings.SphereTraceRadius))
			return false;

		if(!TraceData.Hit.bBlockingHit || !TraceData.Trace.bGrounded)
			return false;

		auto AudioPhysMat = Cast<UPhysicalMaterialAudioAsset>(TraceData.GroundedPhysMat.AudioAsset);

		FPlayerFootstepParams FootstepParams;
		FootstepParams.MakeUpGain = TraceData.Settings.MakeUpGain;
		FootstepParams.Pitch = TraceData.Settings.Pitch;
		FootstepParams.AudioPhysMat = AudioPhysMat;

		const FName MovementTag = Fairy.MoveAudioComp.GetActiveMovementTag(PLAYER_FOOT_GROUP);
		// FName WantedTag = MovementTag;
		// CheckMovementTagOverride(MovementTag, WantedTag);

		const FName MaterialTag = AudioPhysMat.FootstepData.FootstepTag;
		MaterialComp.GetMaterialEvent(MaterialTag, MovementTag, Foot, Foot, FootstepParams.MaterialEvent);

		UTundraPlayerFairyEffectHandler::Trigger_OnFootstepTrace_Plant(Fairy, FootstepParams);
		return true;
	}

	float GetScaledTraceLength(const float MovementSpeed, FPlayerFootstepTraceData& InFootstepTraceData) const
	{
		const float NormalizedSpeed = MovementSpeed / InFootstepTraceData.Settings.MaxVelo;
		const float Alpha = Math::Pow(NormalizedSpeed, 2.0);
		const float ScaledLength = Math::Lerp(InFootstepTraceData.Settings.MinLength, InFootstepTraceData.Settings.MaxLength, Alpha);
		return ScaledLength;
	}

	FVector GetTraceFrameEndPos(USkeletalMeshComponent Mesh, const FPlayerFootstepTraceData& InTraceData, const float InTraceLength) const
	{	
		FVector Direction;
		if(InTraceData.Settings.WorldTarget != nullptr)
		{
			Direction = (InTraceData.Settings.WorldTarget.GetWorldLocation() - InTraceData.Start).GetSafeNormal();
		}
		else
		{
			const FRotator TraceRot = Mesh.GetSocketRotation(InTraceData.Settings.SocketName);
			Direction = TraceRot.ForwardVector;
		}

		return InTraceData.Start - Direction * -InTraceLength;
	}
	
	bool CheckMovementTagOverride(const FName& InTag, FName& OutOverridenTag) const
	{
		if(InTag == n"LandSoft")
		{
			OutOverridenTag = n"Land_BothLegs_LowInt";
			return true;
		}
		if(InTag == n"LandOneLeg")
		{
			OutOverridenTag = n"Land_OneLeg_LowInt";
			return true;
		}		

		return false;
	}

}