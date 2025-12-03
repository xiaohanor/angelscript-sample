class USkylineSentryBossPulseTurretRiseCapability : UHazeCapability
{

	default CapabilityTags.Add(n"PulseTurretRise");

	ASkylineSentryBossPulseTurret PulseTurret;


	FVector TargetPosition;
	float RiseDistance = 1150;
	float RiseSpeed = 300;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PulseTurret = Cast<ASkylineSentryBossPulseTurret>(Owner);	
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (PulseTurret.bHasRisen)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (PulseTurret.bHasRisen)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TargetPosition = PulseTurret.ActorLocation + PulseTurret.ActorUpVector * RiseDistance;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		PulseTurret.GravityWhipTargetComponent.Enable(Owner);
		PulseTurret.AlignmentComp.bIsMoving = true;

	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		PulseTurret.MeshRoot.WorldLocation = Math::VInterpConstantTo(PulseTurret.MeshRoot.WorldLocation, TargetPosition, DeltaTime, RiseSpeed);

		if((PulseTurret.MeshRoot.WorldLocation - TargetPosition).IsNearlyZero())
			PulseTurret.bHasRisen = true;
	}
}