
class USummitStoneBeastCrystalTurretTrackTargetBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	FVector InitialUpDir;
	AAISummitStoneBeastCrystalTurret CrystalTurret;

	USummitStoneBeastCrystalTurretSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		InitialUpDir = Owner.ActorUpVector;
		CrystalTurret = Cast<AAISummitStoneBeastCrystalTurret>(Owner);
		Settings = USummitStoneBeastCrystalTurretSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasGeometryVisibleTarget())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!TargetComp.HasGeometryVisibleTarget())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
	}

	float DelayTime = 0.5;
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration < DelayTime)
			return;

		TargetDirectly(DeltaTime);
	}

	private void TargetDirectly(float DeltaTime)
	{
		FVector TargetLoc = TargetComp.Target.ActorCenterLocation;	
			
		FVector Dir = (TargetLoc - Owner.ActorCenterLocation).GetSafeNormal();
		
		// Ease rotation for holder
		FVector CurrentDir = CrystalTurret.BasePivot.WorldRotation.Vector().GetSafeNormal();
		const float RotationSpeed = 10;
		float Delta = RotationSpeed * DeltaTime;
		CurrentDir = CurrentDir.SlerpTowards(Dir, Delta);

		CrystalTurret.BasePivot.SetWorldRotation(FRotator::MakeFromZX(InitialUpDir, CurrentDir));

		// Ease rotation for barrel
		FVector CurrentGunDir = CrystalTurret.BarrelPivot.WorldRotation.Vector().GetSafeNormal();
		const float HolderRotationSpeed = 10;
		float HolderDelta = HolderRotationSpeed * DeltaTime;
		CurrentGunDir = CurrentGunDir.SlerpTowards(Dir, HolderDelta);
		FVector RightVector = CrystalTurret.BarrelPivot.GetRightVector();
		CrystalTurret.BarrelPivot.SetWorldRotation(FRotator::MakeFromYX(RightVector, CurrentGunDir));
	}
	
}
