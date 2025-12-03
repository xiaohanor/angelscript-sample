event void FOnDisconnected();
event void FOnReconnected();
event void FOnDamaged();

UCLASS(Abstract)
class AIslandShootableClamp : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent MoveRootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent MoveRootComp2;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UCapsuleComponent CapsuleCollision;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent BaseTop;	
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent BaseBottom;
	
	UPROPERTY(DefaultComponent, Attach = MoveRootComp)
	UStaticMeshComponent MovingTop;	
	UPROPERTY(DefaultComponent, Attach = MoveRootComp2)
	UStaticMeshComponent MovingBottom;	
	UPROPERTY(DefaultComponent)
	UScifiCopsGunImpactResponseComponent CopsGunImpactResponsComponent;
	UPROPERTY(DefaultComponent, Attach = MoveRootComp2)
	UScifiCopsGunShootTargetableComponent CopsGunShootTargetableComponent_AttachedAndFlying;
	UPROPERTY(DefaultComponent, Attach = MoveRootComp2)
	UScifiCopsGunShootTargetableComponent CopsGunShootTargetableComponent_Hands;
	UPROPERTY(DefaultComponent, Attach = MoveRootComp)
	UPointLightComponent UpPointLight;
	UPROPERTY(DefaultComponent, Attach = MoveRootComp)
	UPointLightComponent DownPointLight;

	UPROPERTY(DefaultComponent, Attach = MoveRootComp)
	UNiagaraComponent NiagraComp;
	UPROPERTY(DefaultComponent, Attach = MoveRootComp)
	UNiagaraComponent NiagraComp2;

	UPROPERTY()
	FOnDisconnected OnDisconnected;
	UPROPERTY()
	FOnReconnected OnReconnected;
	UPROPERTY()
	FOnDamaged OnDamaged;

	FHazeAcceleratedVector AcceleratedVector;
	FHazeAcceleratedVector AcceleratedVector2;

	bool bIsDown = false;
	UPROPERTY(EditAnywhere)
	int Health = 3;
	int HealthTemp;

	UPROPERTY(EditAnywhere)
	float bDownTimer = 3.0;
	float bDownTimerTemp;
	bool bActorIsStopped = false;

	UPROPERTY(EditAnywhere, ToolTip="This sets the angle at which an attached gun will find the target")
	float AttachedGunMaxAngle = 30.0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{	
		CopsGunShootTargetableComponent_Hands.bCanTargetWhileHandShooting = true;
		CopsGunShootTargetableComponent_Hands.bCanTargetWhileFreeFlying = false;
		CopsGunShootTargetableComponent_Hands.bCanTargetWhileEnvironmentAttached = false;
		CopsGunShootTargetableComponent_AttachedAndFlying.bCanTargetWhileHandShooting = false;
		CopsGunShootTargetableComponent_AttachedAndFlying.bCanTargetWhileFreeFlying = true;
		CopsGunShootTargetableComponent_AttachedAndFlying.bCanTargetWhileEnvironmentAttached = true;
		CopsGunShootTargetableComponent_AttachedAndFlying.bUseVariableAutoAimMaxAngle = false;
		CopsGunShootTargetableComponent_AttachedAndFlying.AutoAimMaxAngle = AttachedGunMaxAngle;

		

	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CopsGunImpactResponsComponent.OnBulletImpact.AddUFunction(this, n"OnGunsImpact");
		DownPointLight.SetVisibility(false);
		HealthTemp = Health;
	//	CopsGunImpactResponsComponent.OnWeaponImpact.AddUFunction(this, n"OnWeaponImpact");.
	}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bIsDown)
		{
			AcceleratedVector.SpringTo(FVector(0,0,50), 15, 0.9, DeltaSeconds);
			AcceleratedVector2.SpringTo(FVector(0,0,-50), 15, 0.9, DeltaSeconds);
		}
		else
		{
			AcceleratedVector.SpringTo(FVector(0,0,0), 15, 0.9, DeltaSeconds);
			AcceleratedVector2.SpringTo(FVector(0,0,0), 15, 0.9, DeltaSeconds);
		}

		MoveRootComp.SetRelativeLocation(AcceleratedVector.Value);
		MoveRootComp2.SetRelativeLocation(AcceleratedVector2.Value);

		if(bActorIsStopped)
			return;

		if(!bIsDown)
			return;

		bDownTimerTemp -=DeltaSeconds;
		if(bDownTimerTemp <= 0)
		{
			OnReconnected.Broadcast();
		//	NiagraComp.Activate();
		//	NiagraComp2.Activate();
			bIsDown = false;
			HealthTemp = Health;
			UpPointLight.SetVisibility(true);
			DownPointLight.SetVisibility(false);
			CopsGunShootTargetableComponent_Hands.Enable(this);
			CopsGunShootTargetableComponent_AttachedAndFlying.Enable(this);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	protected void OnGunsImpact(AHazePlayerCharacter ImpactInstigator, FCopsGunBulletImpactParams ImpactParams)
	{
		if(bActorIsStopped)
			return;
		if(bIsDown)
			return;

		OnDamaged.Broadcast();
		HealthTemp -= 1;
		if(HealthTemp <= 0)
		{
			OnDisconnected.Broadcast();
		//	NiagraComp.Deactivate();
		//	NiagraComp2.Deactivate();
			bIsDown = true;
			bDownTimerTemp = bDownTimer;
			UpPointLight.SetVisibility(false);
			DownPointLight.SetVisibility(true);
			CopsGunShootTargetableComponent_Hands.Disable(this);
			CopsGunShootTargetableComponent_AttachedAndFlying.Disable(this);
		}
	}


	UFUNCTION(BlueprintCallable)
	void StopClampActor()
	{
		bActorIsStopped = true;
		NiagraComp.Deactivate();
		NiagraComp2.Deactivate();
		MovingBottom.SetHiddenInGame(true);
		MovingBottom.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		BaseBottom.SetHiddenInGame(true);
		BaseBottom.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		UpPointLight.SetVisibility(false);
		if(!CopsGunShootTargetableComponent_Hands.IsDisabled())
			CopsGunShootTargetableComponent_Hands.Disable(this);
		if(!CopsGunShootTargetableComponent_AttachedAndFlying.IsDisabled())
			CopsGunShootTargetableComponent_AttachedAndFlying.Disable(this);
	}

}
