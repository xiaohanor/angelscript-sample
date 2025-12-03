class USandSharkLungeMoveCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(SandSharkTags::SandShark);
	default CapabilityTags.Add(SandSharkTags::SandSharkLunge);

	default CapabilityTags.Add(SandSharkBlockedWhileIn::AttackFromBelow);
	default CapabilityTags.Add(SandSharkBlockedWhileIn::Distract);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = SandShark::TickGroupOrder::Lunge;
	default TickGroupSubPlacement = 1;

	ASandShark SandShark;
	USandSharkMovementComponent MoveComp;
	USandSharkLungeComponent LungeComp;
	USandSharkAnimationComponent AnimationComp;
	USandSharkSettings SharkSettings;

	float InitialSpeed = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SandShark = Cast<ASandShark>(Owner);
		MoveComp = USandSharkMovementComponent::Get(Owner);
		LungeComp = USandSharkLungeComponent::Get(Owner);
		AnimationComp = USandSharkAnimationComponent::Get(Owner);
		SharkSettings = USandSharkSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!LungeComp.bIsLunging)
			return false;

		if (LungeComp.State != ESandSharkLungeState::None)
			return false;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!LungeComp.bIsLunging)
			return true;

		if (LungeComp.State != ESandSharkLungeState::Moving)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AnimationComp.AddAnimChaseInstigator(this);
		InitialSpeed = Math::Max(MoveComp.AccMovementSpeed.Value, 500);
		LungeComp.State = ESandSharkLungeState::Moving;
		MoveComp.AccDive.SnapTo(0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AnimationComp.RemoveAnimChaseInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl())
		{
			auto Player = SandShark.GetTargetPlayer();
			auto PlayerLocation = Desert::GetLandscapeLocation(Player.ActorLocation + Player.ActorVelocity * DeltaTime);
			FVector NearestLocation = PlayerLocation;
			bool bFoundNavLocation = Pathfinding::FindNavmeshLocation(PlayerLocation, SandShark::Navigation::AgentRadius, SandShark::Navigation::AgentHeight, NearestLocation);
			if (!bFoundNavLocation || !SandShark.IsTargetPlayerAttackable())
			{
				LungeComp.bTargetBecameUnattackable = true;
				return;
			}

			MoveComp.MoveNavigateToLocation(
				SharkSettings.ChaseMovement,
				NearestLocation,
				DeltaTime,
				InitialSpeed,
				this);
		}
		else
		{
			MoveComp.ApplyCrumbSyncedLocationAndRotation(this);
		}
	}
};