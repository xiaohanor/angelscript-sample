class UEvergreenBarrelCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(CapabilityTags::Movement);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::InfluenceMovement;
	default TickGroupOrder = 2;

	UPlayerMovementComponent MoveComp;
	UEvergreenBarrelPlayerComponent BarrelPlayerComp;
	UTundraPlayerShapeshiftingComponent ShapeshiftingComp;
	UTeleportingMovementData Movement;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		BarrelPlayerComp = UEvergreenBarrelPlayerComponent::GetOrCreate(Player);
		Movement = MoveComp.SetupTeleportingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(CurrentBarrel == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(CurrentBarrel == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		MoveComp.FollowComponentMovement(CurrentBarrel.RootComponent, this);
		MoveComp.ActiveConstrainRotationToHorizontalPlane.Apply(false, this);

		// Because of tick order shapeshifting component is created later than this barrel so we can't cache the reference in BeginPlay
		ShapeshiftingComp = UTundraPlayerShapeshiftingComponent::Get(Player);
		ShapeshiftingComp.AddShapeTypeBlocker(ETundraShapeshiftShape::Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		MoveComp.UnFollowComponentMovement(this);
		MoveComp.ActiveConstrainRotationToHorizontalPlane.Clear(this);
		BarrelPlayerComp.ExitBarrel();
		ShapeshiftingComp.RemoveShapeTypeBlockerInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"AirMovement");
		}
	}

	AEvergreenBarrel GetCurrentBarrel() const property
	{
		return BarrelPlayerComp.CurrentBarrel;
	}
}