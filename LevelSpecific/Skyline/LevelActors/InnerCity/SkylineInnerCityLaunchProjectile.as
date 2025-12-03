event void FSkylineInnerCityLaunchProjectile();

UCLASS(Abstract)
class USkylineInnerCityLaunchProjectileEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunch()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExplode()
	{
	}

};	

class ASkylineInnerCityLaunchProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UStaticMeshComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent ProjectileMesh;

	UPROPERTY(DefaultComponent,Attach = ProjectileMesh)
	UGrappleLaunchPointComponent LaunchPointComp;

	float ExpireTime = 5.0;
	float DestroyTime = 20.0;
	float ResetTime = 2.0;
	bool bReset = true;
	bool bExpired = false;
	FVector LaunchImpulse;
	
	FSkylineInnerCityLaunchProjectile OnExpire;
	FSkylineInnerCityLaunchProjectile OnReset;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem ExplosionVFX;

	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);
		
		ProjectileMesh.SetSimulatePhysics(true);
		
		ProjectileMesh.AddImpulse(LaunchImpulse);
		ProjectileMesh.LinearDamping = .5;

		LaunchPointComp.OnPlayerInitiatedGrappleToPointEvent.AddUFunction(this, n"HandleInitiateGrapple");
		LaunchPointComp.OnPlayerFinishedGrapplingToPointEvent.AddUFunction(this, n"HandleFinishedGrapple");
		USkylineInnerCityLaunchProjectileEventHandler::Trigger_OnLaunch(this);
	
	}

	UFUNCTION()
	private void HandleFinishedGrapple(AHazePlayerCharacter Player,
	                                   UGrapplePointBaseComponent GrapplePoint)
	{
		//Niagara::SpawnOneShotNiagaraSystemAtLocation(ExplosionVFX, ProjectileMesh.GetWorldLocation());
		USkylineInnerCityLaunchProjectileEventHandler::Trigger_OnLaunch(this);
		//SetActorHiddenInGame(true);
	}

	UFUNCTION()
	private void HandleInitiateGrapple(AHazePlayerCharacter Player, UGrapplePointBaseComponent GrapplePoint)
	{
		//ProjectileMesh.SetSimulatePhysics(false);
		Player.ResetAirJumpUsage();

	}

	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(GameTimeSinceCreation > ResetTime && bReset)
		{
			bReset = false;
			OnExpire.Broadcast();
		}
	
		if(GameTimeSinceCreation > ExpireTime && !bExpired)
		{
			bExpired = true;
			ProjectileMesh.SetSimulatePhysics(false);
			AddActorDisable(n"Expired");
		}

		if(GameTimeSinceCreation > DestroyTime)
		{
			DestroyActor();
		}
	}
};