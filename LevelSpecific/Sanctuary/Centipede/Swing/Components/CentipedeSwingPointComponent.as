USTRUCT()
struct FCentipedeSwingPointSettings
{
	// This will constrain the swing movement to the actor's up plane
	UPROPERTY()
	bool bConstrainSwingToUpVector;
}

class UCentipedeSwingPointComponent : UCentipedeSwingJumpTargetComponent
{
	default ActivationRange = 400.0;
	default AdditionalVisibleRange = 2000.0;
	default ForwardVectorCutOffAngle = 180.0;
	default bTestCollision = true;
	default bVisualizeComponent = true;

	UPROPERTY(EditAnywhere)
	FCentipedeSwingPointSettings SwingPointSettings;
	default SwingPointSettings.bConstrainSwingToUpVector = true;

	UPROPERTY(EditInstanceOnly)
	bool bJumpAutoTargeting = true;

	UPROPERTY(EditInstanceOnly)
	bool bCanPlayerLetGo = true;

	// Eman TODO: MAAAAAAAYBE use lock only for starter swing poitns?? We'll see....
	// This MUST be used on "starting" swing points, where both players have access
	// UPROPERTY(EditInstanceOnly)
	// bool bUseNetworkLock = false;

	// gIGgity
	private AHazePlayerCharacter Swinger = nullptr;

	// Used to handle mutex interactions between players
	// UNetworkLockComponent NetworkLockComponent;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		// NetworkLockComponent = UNetworkLockComponent::Create(Owner, FName(Name + "_NetworkLock"));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Super::Tick(DeltaSeconds);

		// for (auto Player : Game::Players)
		// {
		// 	float Score = GetPlayerNetworkLockScore(Player);
		// 	NetworkLockComponent.ApplyOwnerHint(Player, this, Score);
		// }
	}

	// Disables targetable for all players
	void OccupySwingPoint(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		Swinger = Player;
		Disable(Instigator);
	}

	// Re-enables targetable
	void FreeSwingPoint(FInstigator Instigator)
	{
		Swinger = nullptr;
		Enable(Instigator);
	}

	private float GetPlayerNetworkLockScore(AHazePlayerCharacter Player)
	{
		// Best score the closer the player is to this swing point
		float DistanceScore = 1.0 - Math::Saturate(Player.ActorLocation.DistSquared(WorldLocation) / Math::Square(ActivationRange));

		// Are we missing something?? Maybe check player's future location?
		// ...
		// ...

		float FinalScore = DistanceScore;
		return FinalScore;
	}

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		if (UPlayerCentipedeSwingComponent::Get(Query.Player).GetActiveSwingPoint() == this)
			return false;

		if (!VerifyBaseTargetableConditions(Query))
			return false;

		Targetable::ApplyVisibleRange(Query, ActivationRange + AdditionalVisibleRange);
		Targetable::ApplyTargetableRange(Query, ActivationRange);
		Targetable::ApplyVisualProgressFromRange(Query, ActivationRange + AdditionalVisibleRange, ActivationRange);

		//Query.Result.bVisible = false;

		if (bTestCollision)
			return Targetable::RequireNotOccludedFromCamera(Query, bIgnoreOwnerCollision = bIgnorePointOwner);

		return true;
	}

	FVector GetJumpImpulseForPlayer(AHazePlayerCharacter Player, float GravityMagnitude) const override
	{
		FVector TargetToPlayer = (Player.ActorLocation - WorldLocation).GetSafeNormal();
		FVector TargetLocation = WorldLocation + TargetToPlayer * Centipede::PlayerMeshMandibleOffset * 0.75;

		float Height = Math::Max(0.0, TargetLocation.Z - Player.ActorLocation.Z) + Centipede::SwingJumpHeight;
		return Trajectory::CalculateVelocityForPathWithHeight(Player.ActorLocation, TargetLocation, GravityMagnitude, Height);
	}

	void ConstrainVelocityToSwingPlane(FVector& OutVelocity)
	{
		if (SwingPointSettings.bConstrainSwingToUpVector)
			OutVelocity = OutVelocity.ConstrainToPlane(SwingPlaneVector);
	}

	FVector GetSwingPlaneVector() const property
	{
		return Owner.ActorUpVector;
	}

	FVector GetNormalVector() const override
	{
		return GetSwingPlaneVector();
	}

	AHazePlayerCharacter GetActiveSwingingPlayer() const
	{
		return Swinger;
	}

	bool IsOccupied() const
	{
		return Swinger != nullptr;
	}
}