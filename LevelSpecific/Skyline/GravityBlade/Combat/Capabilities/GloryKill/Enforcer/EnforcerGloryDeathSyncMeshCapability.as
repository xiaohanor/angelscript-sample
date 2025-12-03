class UGravityBladeCombatEnforcerGloryDeathSyncMeshCapability : UHazeCapability
{
	default CapabilityTags.Add(n"GloryKill");
	default CapabilityTags.Add(BasicAITags::Death);

	// Needs to occur after player animations have been evaluated to match up with align bone.
	// This will move mesh to exactly match with player, ...GloryDeathMovementCapabilty tries 
	// to move the actor location to match so we can request animation at an earlier tick group. 
	default TickGroup = EHazeTickGroup::PostWork;

	// No need to network, movement capability will sync GloryDeathComp.bShouldGloryDie
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	UGravityBladeCombatEnforcerGloryDeathComponent GloryDeathComp;
	UBasicAICharacterMovementComponent MoveComp;
	UGravityBladeCombatUserComponent KillerComp;
	UHazeCharacterSkeletalMeshComponent Mesh;

	FTransform OriginalTransform;
	FTransform OriginalRelativeTransform;
	FHazeAcceleratedTransform AccTransform;

	const float AlignBoneLerpDuration = 0.2;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GloryDeathComp = UGravityBladeCombatEnforcerGloryDeathComponent::GetOrCreate(Owner);
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner); 
		Mesh = Cast<AHazeCharacter>(Owner).Mesh;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!GloryDeathComp.bShouldGloryDie)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!GloryDeathComp.bShouldGloryDie)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		KillerComp = UGravityBladeCombatUserComponent::Get(Game::Mio);
		OriginalTransform = Mesh.WorldTransform;
		OriginalRelativeTransform = Mesh.RelativeTransform;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// Snap, we should be hidden by now
		Mesh.SetRelativeTransform(OriginalRelativeTransform);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Mesh.IsSimulatingPhysics())
			return;

		if (KillerComp.bGloryKillActive || (ActiveDuration < AlignBoneLerpDuration))
		{
			// Align until player blends out of glory kill.
			float Alpha = Math::Min(ActiveDuration / AlignBoneLerpDuration, 1.0);

			FTransform LocalAlign = GloryDeathComp.KillerPlayer.Mesh.GetSocketTransform(n"Align", ERelativeTransformSpace::RTS_Actor);
			FTransform TargetTransform = FTransform(KillerComp.GloryKillWantedPlayerRotation, GloryDeathComp.KillerPlayer.ActorLocation);
			FTransform AlignTransform = LocalAlign * TargetTransform;

			// Target maintains height, player will have to rise/fall to compensate
			AlignTransform.Location = AlignTransform.Location.PointPlaneProject(Owner.ActorLocation, Owner.ActorUpVector);

			// Lerp instead of accelerate to ensure we get perfect match once alpha is 1
			Mesh.SetWorldLocation(Math::Lerp(OriginalTransform.Location, AlignTransform.Location + OriginalRelativeTransform.Location, Alpha));
			Mesh.SetWorldRotation(FQuat::Slerp(OriginalTransform.Rotation, AlignTransform.Rotation * OriginalRelativeTransform.Rotation, Alpha).Rotator()) ;
			AccTransform.SnapTo(Mesh.RelativeTransform); // Could use some velocity here as well, but meh
		}
		else 
		{
			// Player has moved along, move mesh back to normal relative location
			AccTransform.AccelerateTo(OriginalRelativeTransform, 1.0, DeltaTime);
			Mesh.SetRelativeTransform(AccTransform.Value);
		}
	}
}