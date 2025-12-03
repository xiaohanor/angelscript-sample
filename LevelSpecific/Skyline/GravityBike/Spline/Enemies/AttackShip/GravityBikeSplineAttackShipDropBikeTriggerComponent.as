UCLASS(NotBlueprintable)
class UGravityBikeSplineAttackShipDropBikeTriggerComponent : UGravityBikeSplineEnemyTriggerComponent
{
	UPROPERTY(EditAnywhere)
	AGravityBikeSplineBikeEnemy BikeEnemy;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		if(BikeEnemy == nullptr)
		{
			PrintError(f"No BikeEnemy assigned on {this}");
			DestroyComponent(Owner);
			return;
		}

		if(BikeEnemy.bStartActivated)
			PrintWarning(f"{BikeEnemy} is bStartActivated, while it will also be dropped by a bike. Turn off StartActivated if it should be dropped!");
	}

	void OnEnemyEnter(UGravityBikeSplineEnemyTriggerUserComponent TriggerUserComp, bool bIsTeleport) override
	{
		Super::OnEnemyEnter(TriggerUserComp, bIsTeleport);

		if(bIsTeleport)
			return;

		auto AttackShip = Cast<AGravityBikeSplineAttackShip>(TriggerUserComp.Owner);
		if(AttackShip == nullptr)
			return;

		BikeEnemy.SetActorLocationAndRotation(AttackShip.ActorLocation, AttackShip.ActorRotation, true);
		BikeEnemy.SetActorVelocity(AttackShip.ActorVelocity);
		BikeEnemy.RemoveActorDisable(this);
		BikeEnemy.ActivateFromAttackShipDropBike(AttackShip, this);

		auto DropComp = UGravityBikeSplineBikeEnemyDropComponent::Get(BikeEnemy);
		if(DropComp == nullptr)
			return;

		DropComp.bIsDropping = true;
		DropComp.AttackShip = AttackShip;
	}
};