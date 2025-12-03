asset SkylineSentryBossMioSheet of UHazeCapabilitySheet
{
	Capabilities.Add(USkylineSentryBossCameraCapability);
	Capabilities.Add(USkylineSentryBossTunnelCameraCapability);
}

enum EBossState
{
	Idle = 0,
	DefenseSystem1 = 1,
	DefenseSystem2 = 2,
	DefenseSystem3 = 3,
	DefenseSystem4 = 4,
	DefenseSystem5 = 7
}

UCLASS(HideCategories = "InternalHiddenObjects")
class ASKylineSentryBoss : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USpringArmCamera DefaultCamera;
	//default DefaultCamera.BlendOutBehaviour = EHazeCameraBlendoutBehaviour::LockView;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeCameraComponent TunnelCamera;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent BaseMesh;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent Collisions;

	UPROPERTY(DefaultComponent, Attach = Collisions)
	UStaticMeshComponent ShutterCollision;
	default ShutterCollision.bHiddenInGame = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	UGravityBladeGrappleComponent GrappleComp;

	UPROPERTY(DefaultComponent)
	UPlayerInheritMovementComponent InheritMoveComp;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestCapabilityComp;
	default RequestCapabilityComp.InitialStoppedSheets_Mio.Add(SkylineSentryBossMioSheet);

	UPROPERTY(DefaultComponent)
	UGravityBladeGravityShiftComponent GravityShiftComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineSentryBossStateManagerCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineSentryBossLookAtCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineSentryBossHazardStateCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineSentryBossPulseStateCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineSentryBossMissileStateCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineSentryBossLaserDroneStateCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineSentryBossMortarStateCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineSentryBossMortarAreaAttackCapability");




	UPROPERTY(DefaultComponent)
	UGravityBladeGrappleResponseComponent BladeResponseComp;

	UPROPERTY(DefaultComponent, ShowOnActor)
	USkylineSentryBossTileManagerComponent TileManager;


	UPROPERTY(EditAnywhere, Category = "Actors")
	ASKylineSentryBossShutter Shutter;

	UPROPERTY(EditAnywhere, Category = "Actors")
	ASkylineSentryBossForceField ForceField;

	UPROPERTY(EditAnywhere, Category = "Actors")
	TArray<ASkylineSentryBossForceFieldEmitter> ForceFieldEmitters;

	UPROPERTY(EditAnywhere, Category = "Actors")
	TArray<ASkylineSentryBossGenerator> Generators;

	UPROPERTY(EditAnywhere, Category = "Actors")
	TArray<ASkylineSentryBossMortarArea> MortarAreas;

	TArray<ASkylineSentryBossTile> Tiles;
	TArray<ASkylineSentryBossMissileTurret> ActiveMissileTurrets;
	TArray<ASkylineSentryBossLaserDrone> ActiveLaserDrones;
	TArray<ASkylineSentryBossPulseTurret> ActivePulseTurrets;


	EBossState BossState;

	int EmittersLeft = 0;
	bool bIsPlayerOnBoss = false;
	AActor Target;
	
	bool bActiveMortarAttack;
	float TimeToMortarAttack;

	USkylineSentryBossPlayerLandedComponent PlayerLandedComp;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<AActor> Children;
		GetAttachedActors(Children);

		for(AActor Child : Children)
		{
			ASkylineSentryBossTile Tile = Cast<ASkylineSentryBossTile>(Child);

			if(Tile != nullptr)
			{
				if(!Tile.bIsInactive)
					Tiles.Add(Tile);
				Tile.Boss = this;
			}
				
		}


		for(ASkylineSentryBossForceFieldEmitter Emitter : ForceFieldEmitters)
		{
			if(Emitter == nullptr)
				return;
			
			EmittersLeft++;
			Emitter.OnEmitterDestroy.AddUFunction(this, n"OnEmitterDestroy");
		}
		
		Shutter.Boss = this;
		Target = Game::Zoe;

		BladeResponseComp.OnPullEnd.AddUFunction(this, n"OnPullEnd");
	}



	UFUNCTION()
	private void OnPullEnd(UGravityBladeGrappleUserComponent _GrappleComp)
	{
		PlayerLandedComp = USkylineSentryBossPlayerLandedComponent::GetOrCreate(Game::Mio);
		PlayerLandedComp.Boss = this;
		PlayerLandedComp.DefaultCamera = DefaultCamera;
		PlayerLandedComp.TunnelCamera = TunnelCamera;

		RequestCapabilityComp.StartInitialSheetsAndCapabilities(Game::Mio, this);
		bIsPlayerOnBoss = true;
		
		ForceField.ActivateForceField();
		for(ASkylineSentryBossForceFieldEmitter Emitter: ForceFieldEmitters)
		{
			Emitter.Activate();
		}
	}

	UFUNCTION(DevFunction)
	void OnLeave()
	{
		RequestCapabilityComp.StopInitialSheetsAndCapabilities(Game::Mio, this);
		bIsPlayerOnBoss = false;
	}

	UFUNCTION()
	private void OnEmitterDestroy()
	{
		EmittersLeft --;

		if(EmittersLeft <= 0)
			ForceField.DeactivateForceField();
	}


	
}