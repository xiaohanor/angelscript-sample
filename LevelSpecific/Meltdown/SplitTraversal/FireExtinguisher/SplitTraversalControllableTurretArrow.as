UCLASS(Abstract)
class USplitTraversalControllableTurretArrowEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHit() {}
}

namespace SplitTraversalControllableTurretArrowConstants
{
	const float Speed = 8000.0;
}

class ASplitTraversalControllableTurretArrow : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY()
	float Radius = 50.0;

	UPROPERTY()
	float LifeTime = 5.0;

	ASplitTraversalControllableTurret ControllableTurretOwner;

	bool bStuck = false;
	bool bHasTriggerImpactAudio = false;

	
	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	UPROPERTY(EditDefaultsOnly, Category = "DeathEffects")
	TSubclassOf<UDeathEffect> DeathEffect;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent QueueComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bStuck)
			return;

		auto Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		//Trace.UseSphereShape(Radius);
		Trace.IgnoreActor(ControllableTurretOwner);

		if(!bHasTriggerImpactAudio)
		{
			const FHitResult Hit = Trace.QueryTraceSingle(ActorLocation, ActorLocation + (ActorForwardVector * 10000));
			if(Hit.bBlockingHit)
			{
				const float TimeToImpact = Hit.Distance / SplitTraversalControllableTurretArrowConstants::Speed;
				USplitTraversalControllableTurretEventHandler::Trigger_OnArrowHit(ControllableTurretOwner, FSplitTraversalControllableTurretArrowParams(Hit.ImpactPoint, TimeToImpact));
				bHasTriggerImpactAudio = true;
			}
		}

		FVector DeltaMovement = ActorForwardVector * SplitTraversalControllableTurretArrowConstants::Speed * DeltaSeconds;

		const FHitResult Hit = Trace.QueryTraceSingle(ActorLocation, ActorLocation + DeltaMovement);
		if(Hit.bBlockingHit)
		{
			auto WaterPot = Cast<ASplitTraversalWaterPot>(Hit.Actor);
			auto Player = Cast<AHazePlayerCharacter>(Hit.Actor);

			if (WaterPot != nullptr)
				WaterPot.Shot();

			else if (Player != nullptr)
			{
				Player.KillPlayer(FPlayerDeathDamageParams(),DeathEffect);
				auto HealthComp = UPlayerHealthComponent::Get(Player);
				HealthComp.OnReviveTriggered.AddUFunction(ControllableTurretOwner, n"HandlePlayerRespawned");
			}

			else
			{
				SetActorLocation(Hit.ImpactPoint);
				Impact();
				return;
			}
		}	

		AddActorWorldOffset(DeltaMovement);

		if (GameTimeSinceCreation > LifeTime)
			DestroyActor();
	}

	private void Impact()
	{
		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();
		BP_Explode();
		bStuck = true;

		USplitTraversalControllableTurretArrowEventHandler::Trigger_OnHit(this);
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Explode(){}
};