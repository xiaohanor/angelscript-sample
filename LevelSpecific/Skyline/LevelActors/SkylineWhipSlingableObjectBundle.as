UCLASS(Abstract)
class USkylineWhipSlingableObjectBundleEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnUnwrap()
	{
	}
};

event void FOnNetDestroyedSignature();

class ASkylineWhipSlingableObjectBundle : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent NetPivot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent StrapPivot;

	UPROPERTY(DefaultComponent)
	UBoxComponent BladeCollison;
	default BladeCollison.bGenerateOverlapEvents = false;
	default BladeCollison.CollisionResponseToAllChannels = ECollisionResponse::ECR_Ignore;
	default BladeCollison.SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceMio, ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent)
	UBoxComponent PlayerCollison;
	default BladeCollison.bGenerateOverlapEvents = false;
	default BladeCollison.CollisionResponseToAllChannels = ECollisionResponse::ECR_Ignore;
	default BladeCollison.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatTargetComponent TargetComp;

	UPROPERTY(DefaultComponent, Attach = TargetComp)
	UTargetableOutlineComponent OutlineComp;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatInteractionResponseComponent BladeCombatResponseComp;
	default BladeCombatResponseComp.InteractionType = EGravityBladeCombatInteractionType::DiagonalUpRight;

	TArray<AWhipSlingableObject> SlingableObjects;

	UPROPERTY()
	FOnNetDestroyedSignature OnDestroyedNet;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike Animation;
	default Animation.Duration = 1.0;
	default Animation.bCurveUseNormalizedTime = true;
	default Animation.Curve.AddDefaultKey(0.0, 0.0);
	default Animation.Curve.AddDefaultKey(1.0, 1.0);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors, true, true);
		for (auto AttachedActor : AttachedActors)
		{
			auto Slingable = Cast<AWhipSlingableObject>(AttachedActor);
			if (Slingable != nullptr)
			{
				SlingableObjects.Add(Slingable);
				Slingable.AddDisabler(this);
			}
		}

		BladeCombatResponseComp.OnHit.AddUFunction(this, n"HandleBladeHit");
		Animation.BindUpdate(this, n"AnimationUpdate");
		Animation.BindFinished(this, n"AnimationFinished");
	}

	UFUNCTION()
	private void AnimationUpdate(float CurrentValue)
	{
		NetPivot.RelativeScale3D = FVector(1.0, 1.0, 1.0 - CurrentValue);
	}

	UFUNCTION()
	private void AnimationFinished()
	{
		for (auto SlingableObject : SlingableObjects)
			SlingableObject.RemoveDisabler(this);
	}

	UFUNCTION()
	private void HandleBladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		BladeCombatResponseComp.AddResponseComponentDisable(this);
		OnDestroyedNet.Broadcast();
		Unwrap();
	}

	UFUNCTION()
	void Unwrap()
	{
		USkylineWhipSlingableObjectBundleEventHandler::Trigger_OnUnwrap(this);

		Animation.Play();

		TargetComp.Disable(this);
		PlayerCollison.AddComponentCollisionBlocker(this);
		BladeCollison.AddComponentCollisionBlocker(this);
		StrapPivot.SetHiddenInGame(true, true);
		BP_Unwrap();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Unwrap() { }
};