
class USkylineTorClearAreaBehaviour : UBasicBehaviour
{	
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	default CapabilityTags.Add(SkylineTorAttackTags::Clear);

	USkylineTorHoldHammerComponent HoldHammerComp;
	USkylineTorSettings Settings;
	UAnimInstanceSkylineTor AnimInstance;

	private AHazeActor Target;
	private AHazeCharacter Character;
	FBasicAIAnimationActionDurations Durations;
	TArray<AHazeActor> HitTargets;

	FHazeAcceleratedFloat AccRot;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HoldHammerComp = USkylineTorHoldHammerComponent::GetOrCreate(Owner);
		Settings = USkylineTorSettings::GetSettings(Owner);
		Character = Cast<AHazeCharacter>(Owner);
		AnimInstance = Cast<UAnimInstanceSkylineTor>(Character.Mesh.AnimInstance);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if(HoldHammerComp.bDetached)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > Durations.GetTotal())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		if (!Owner.ActorCenterLocation.IsWithinDist(Game::Mio.ActorCenterLocation, 300)
			&& !Owner.ActorCenterLocation.IsWithinDist(Game::Zoe.ActorCenterLocation, 300))
			DeactivateBehaviour();

		Durations.Telegraph = 0.1;
		Durations.Action = 0.5;
		Durations.Recovery = 0.1;
		// AnimInstance.FinalizeDurations(FeatureTagSkylineTor::ClearArea, NAME_None, Durations);
		AnimComp.RequestAction(FeatureTagSkylineTor::ClearArea, EBasicBehaviourPriority::Medium, this, Durations);
		HitTargets.Empty();
		AccRot.SnapTo(0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Character.MeshOffsetComponent.SetRelativeRotation(FRotator::ZeroRotator);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Durations.IsInActionRange(ActiveDuration))
		{
			AccRot.SpringTo(360, 50, 0.5, DeltaTime);
			Character.MeshOffsetComponent.RelativeRotation = FRotator(0, AccRot.Value, 0);

			for(AHazePlayerCharacter Player : Game::Players)
			{
				if(HitTargets.Contains(Player))
					continue;

				if(Player.ActorLocation.Dist2D(Owner.ActorLocation, FVector::UpVector) < 500)
				{
					HitTargets.Add(Player);
					
					FStumble Stumble;
					FVector Dir = (Player.ActorLocation - Owner.ActorLocation).GetNormalized2DWithFallback(-Player.ActorForwardVector);
					if (Dir.IsZero())
						Dir = Owner.ActorForwardVector;
					Stumble.Move = Dir * 500;
					Stumble.Duration = 0.5;
					Player.ApplyStumble(Stumble);
				}
			}
		}
	}
}