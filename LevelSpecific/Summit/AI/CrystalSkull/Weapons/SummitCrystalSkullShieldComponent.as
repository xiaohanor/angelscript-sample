class USummitCrystalSkullShieldComponent : UStaticMeshComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;
	default CollisionProfileName = n"NoCollision";
	default bHiddenInGame = true;
	default bCanEverAffectNavigation = false;

	AHazeActor HazeOwner;
	float Roll;
	FName DeployedCollisionProfile = n"BlockAllDynamic";
	bool bDeployed = false;

	FVector OrbitalVelocity;

	USummitCrystalSkullSettings SkullSettings;	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeOwner = Cast<AHazeActor>(Owner);
		SetHiddenInGame(true);
		SkullSettings = USummitCrystalSkullSettings::GetSettings(Cast<AHazeActor>(Owner));
	}

	void SetupFromTemplate(USummitCrystalSkullShieldComponent Template)
	{
		StaticMesh = Template.StaticMesh;
		WorldScale3D = Template.WorldScale;
		for (int i = 0; i < Template.NumMaterials; i++)
		{
			SetMaterial(i, Template.GetMaterial(i));
		}
	}

	void Deploy()
	{
		bDeployed = true;
		SetHiddenInGame(false);
		SetComponentTickEnabled(true);
		SetCollisionProfileName(DeployedCollisionProfile);
		Roll = WorldRotation.Roll;

		// Set random initial orbital velocity
		FVector2D PlaneVelocity = Math::GetRandomPointOnCircle();
		FVector Normal = RelativeLocation.GetSafeNormal();
		FVector NonParallell = (Normal.DotProduct(FVector::ForwardVector) < 0.99) ? FVector::ForwardVector : FVector::UpVector;
		FVector PlaneX = Normal.CrossProduct(NonParallell).GetSafeNormal();
		FVector PlaneY = Normal.CrossProduct(PlaneX);
		OrbitalVelocity = (PlaneX * PlaneVelocity.X + PlaneY * PlaneVelocity.Y) * SkullSettings.DeployShieldsOrbitalSpeed;
	}

	void Destroy()
	{
		if (!bDeployed)
			return;

		bDeployed = false;
		SetHiddenInGame(true);
		SetComponentTickEnabled(false);
		SetCollisionProfileName(n"NoCollision");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime) 
	{
		// Move in orbit
		RelativeLocation += OrbitalVelocity * DeltaTime;  
		FVector Normal = RelativeLocation.GetSafeNormal();
		RelativeLocation = Normal * SkullSettings.DeployShieldsDistance;
		OrbitalVelocity = OrbitalVelocity.ConstrainToPlane(Normal).GetSafeNormal() * SkullSettings.DeployShieldsOrbitalSpeed;

		// Roll in place
		FRotator NewRot = (WorldLocation - AttachParent.WorldLocation).Rotation();
		Roll = FRotator::NormalizeAxis(Roll + DeltaTime * 360.0 * SkullSettings.DeployShieldsRollSpeed);
		NewRot.Roll = Roll;
		SetWorldRotation(NewRot);
	}
}
