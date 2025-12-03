asset GravityBikeSplineBikeEnemyDriverSheet of UHazeCapabilitySheet
{
	Capabilities.Add(UGravityBikeSplineBikeEnemyDriverBlockFireCapability);

	Capabilities.Add(UGravityBikeSplineBikeEnemyDriverDrivingCapability);
	Capabilities.Add(UGravityBikeSplineBikeEnemyDriverGrabbedCapability);
	Capabilities.Add(UGravityBikeSplineBikeEnemyDriverThrownCapability);
	Capabilities.Add(UGravityBikeSplineBikeEnemyDriverDroppedCapability);

	Capabilities.Add(UGravityBikeWhipThrowableGrabbedCapability);
	Capabilities.Add(UGravityBikeWhipThrowableThrownCapability);
};

enum EGravityBikeSplineBikeEnemyDriverState
{
	Driving,
	Grabbed,
	Thrown,
	Dropped,
};

UCLASS(Abstract)
class AGravityBikeSplineBikeEnemyDriver : AGravityBikeWhipThrowable
{
	default DisableComp.bAutoDisable = false;
	default CapabilityComp.DefaultSheets.Add(GravityBikeSplineBikeEnemyDriverSheet);

	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase Mesh;
	default Mesh.CollisionProfileName = n"NoCollision";

	UPROPERTY(EditDefaultsOnly, Category = "Bike Driver")
	bool bIsPassenger = false;

	UPROPERTY(EditDefaultsOnly, Category = "Bike Driver")
	float Gravity = 2000;

	UPROPERTY(EditDefaultsOnly, Category = "Bike Driver")
	float AllowGrabAfterActivationDelay = 2;

	AGravityBikeSplineBikeEnemy Bike;
	EGravityBikeSplineBikeEnemyDriverState State = EGravityBikeSplineBikeEnemyDriverState::Driving;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

        GrabTargetComp.AddTargetCondition(this, FGravityBikeWhipGrabTargetCondition(this, n"GrabTargetCondition"));
	}

	void SetBike(AGravityBikeSplineBikeEnemy InBike)
	{
		Bike = InBike;
	}

	UFUNCTION()
	protected bool GrabTargetCondition()
	{
		if(IsValid(Bike))
		{
			if(Bike.HealthComp.IsDead())
				return false;

			if(!bIsPassenger)
			{
				// Can't target the driver while the passenger is still on the bike
				if(Bike.HasPassenger())
					return false;
			}

			auto DropComp = UGravityBikeSplineBikeEnemyDropComponent::Get(Bike);
			if(DropComp != nullptr && DropComp.bIsDropping)
				return false;

			if(Bike.GetEnabledDuration() < AllowGrabAfterActivationDelay)
				return false;
		}

		return true;
	}

	void EjectFromBike(FVector Velocity)
	{
		if(GrabTargetComp.IsGrabbed())
			return;
		
		SetActorVelocity(Velocity);
		DetachFromActor();
		State = EGravityBikeSplineBikeEnemyDriverState::Dropped;
		GrabTargetComp.GrabState = EGravityBikeWhipGrabState::Dropped;
		SetActorTickEnabled(true);
	}

	FVector GetPistolMuzzleLocation() const
	{
		return Mesh.GetSocketLocation(n"LeftAttach");
	}
};