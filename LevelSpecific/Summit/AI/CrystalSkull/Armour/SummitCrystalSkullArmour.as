UCLASS(Abstract)
class ASummitCrystalSkullArmour : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UAdultDragonTailSmashModeTargetableComponent SmashTargetable;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MainMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UAdultDragonAcidAutoAimComponent AutoAimComp;
	default AutoAimComp.UsableByPlayers = EHazeSelectPlayer::Mio;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCapsuleComponent CapsuleComp;
	default CapsuleComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);
	default CapsuleComp.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	default CapsuleComp.SetCollisionResponseToChannel(ECollisionChannel::PlayerAiming, ECollisionResponse::ECR_Ignore);

	UPROPERTY(DefaultComponent, Attach = Root)
	UAcidResponseComponent AcidResponseComp;

	USummitCrystalSkullArmourSettings Settings;

	TArray<FSummitCrystalSkullArmourPiece> ArmourPieces;

	float ImpulseForce = 65000.0;
	float DestroyedTime = BIG_NUMBER;

	bool bIgnoreAcid = false;
	int HitCount;
	int DestroyedCount = 0; 

	float DissolveStart = -0.1;
	float DissolveTarget = 0.8;
	float CurrentDissolve;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MainMesh.SetScalarParameterValueOnMaterials(n"DissolveStep", DissolveStart);
		CurrentDissolve = DissolveStart;

		Settings = USummitCrystalSkullArmourSettings::GetSettings(this);

		AcidResponseComp.OnAcidHit.AddUFunction(this, n"OnAcidHit");

		TArray<UStaticMeshComponent> Meshes;
		MainMesh.GetChildrenComponentsByClass(UStaticMeshComponent, true, Meshes);
		ArmourPieces.SetNum(Meshes.Num());
		for (int i = 0; i < Meshes.Num(); i++)
		{
			ArmourPieces[i].Mesh = Meshes[i];
			ArmourPieces[i].OriginalLocation = Meshes[i].RelativeLocation;	
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if ((Time::GameTimeSeconds < DestroyedTime) && (CurrentDissolve > DissolveStart))
		{
			CurrentDissolve = Math::FInterpConstantTo(CurrentDissolve, DissolveStart, DeltaSeconds, 0.45);
			MainMesh.SetScalarParameterValueOnMaterials(n"DissolveStep", CurrentDissolve);
		}
	}
	
	UFUNCTION()
	private void OnAcidHit(FAcidHit Hit)
	{
		if (bIgnoreAcid)
			return;

		if (Time::GameTimeSeconds > DestroyedTime)
			return;
		
		if (HitCount == 0)
		{	
			FStormSiegeMetalAcidifiedParams Params;
			Params.AttachComp = MeshRoot;
		}

		HitCount++;

		if (HitCount < Settings.HitPoints)
			return;

		Destroy();
	}

	void Regrow()
	{
		DestroyedTime = BIG_NUMBER;
		HitCount = 0;
		MainMesh.SetHiddenInGame(false);

		for (FSummitCrystalSkullArmourPiece& ArmourPiece : ArmourPieces)
		{
			ArmourPiece.Mesh.SetSimulatePhysics(false);
			ArmourPiece.Mesh.SetHiddenInGame(true);
			ArmourPiece.Mesh.SetCollisionProfileName(n"NoCollision");
			ArmourPiece.Mesh.AttachTo(MainMesh);
			ArmourPiece.Mesh.RelativeLocation = ArmourPiece.OriginalLocation;
		}

		CapsuleComp.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
		AutoAimComp.Enable(this);

		FSummitCrystalSkullArmourRegrowParams Params;
		Params.Location = ActorLocation;
		USummitCrystalSkullArmourEventHandler::Trigger_OnRegrow(this, Params);
	}

	void Destroy()
	{
		DestroyedTime = Time::GameTimeSeconds;

		for (FSummitCrystalSkullArmourPiece& ArmourPiece : ArmourPieces)
		{
			ArmourPiece.Mesh.DetachFromParent();
			ArmourPiece.Mesh.SetHiddenInGame(false);
			ArmourPiece.Mesh.SetCollisionProfileName(n"PhysicsActor");
		 	ArmourPiece.Mesh.SetSimulatePhysics(true);
			FVector Impulse = (ArmourPiece.Mesh.WorldLocation - ActorLocation).GetSafeNormal() * ImpulseForce;
			ArmourPiece.Mesh.AddImpulse(Impulse);
		}

		MainMesh.SetHiddenInGame(true);

		CapsuleComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		AutoAimComp.Disable(this);

		FSummitCrystalSkullArmourDestroyedParams Params;
		Params.Location = ActorLocation;
		USummitCrystalSkullArmourEventHandler::Trigger_OnDestroyed(this, Params);
		CurrentDissolve = DissolveTarget;

		DestroyedCount++;
	}
}

struct FSummitCrystalSkullArmourPiece
{
	UStaticMeshComponent Mesh;
	FVector OriginalLocation;
}
