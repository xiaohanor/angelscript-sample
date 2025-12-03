
class USanctuaryGhostRecoverBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	USanctuaryGhostSettings GhostSettings;

	FVector RecoverLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		GhostSettings = USanctuaryGhostSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > GhostSettings.RecoverDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		FVector OwnLoc = Owner.ActorLocation;

		// Recover to somewhere ahead in players view
		auto TargetPlayer = Cast<AHazePlayerCharacter>(TargetComp.Target);
		FVector RecoverDir = TargetPlayer.ViewRotation.ForwardVector.GetSafeNormal2D();
		RecoverLocation = OwnLoc + RecoverDir * GhostSettings.ChargeRange;

		// Try to end up on navmesh
		FVector NavmeshLocation;
		if (UNavigationSystemV1::ProjectPointToNavigation(RecoverLocation, NavmeshLocation, nullptr, nullptr, FVector(300.0, 300.0, 200.0)))
			RecoverLocation = NavmeshLocation;		

		AnimComp.RequestFeature(LocomotionFeatureAISanctuaryTags::GhostKnightAttack, SubTagSanctuaryGhostKnightAttack::Recover, EBasicBehaviourPriority::Medium, this);

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;		
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugLine(Owner.ActorCenterLocation, RecoverLocation, FLinearColor::Yellow, 5, 5.0);
			Debug::DrawDebugLine(RecoverLocation, RecoverLocation + FVector(0.0, 0.0, 100.0), FLinearColor::Yellow, 5, 5.0);
		}
#endif				
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DestinationComp.MoveTowards(RecoverLocation, 3000.0);		
	}
}