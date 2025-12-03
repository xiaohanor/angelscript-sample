event void FSkylineMovableTimeLikeObjectSignature();

class ASkylineMovableTimeLikeObject : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent)
	USceneComponent EndPosition;

	UPROPERTY(DefaultComponent)
	USceneComponent MovableObject;

	UPROPERTY(DefaultComponent, Attach = MovableObject)
	UBoxComponent Collision;
	default Collision.SetCollisionProfileName(n"OverlapAllDynamic");
	default Collision.SetCollisionResponseToChannel(ECollisionChannel::EnemyCharacter, ECollisionResponse::ECR_Block);

	UPROPERTY(EditAnywhere)
	float AnimationDuration = 1.0;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike  MoveAnimation;
	default MoveAnimation.Duration = 5.0;
	default MoveAnimation.Curve.AddDefaultKey(0.0, 0.0);
	default MoveAnimation.Curve.AddDefaultKey(5.0, 1.0);

	FTransform StartingTransform;
	FQuat StartingRotation;
	FVector StartingPosition;
	FTransform EndingTransform;
	FQuat EndingRotation;
	FVector EndingPosition;

	UPROPERTY()
	FSkylineMovableTimeLikeObjectSignature OnReachedtDestination;

	UPROPERTY(EditAnywhere, Category = "Damage")
	bool bDamage = true;

	UPROPERTY(EditAnywhere, Category = "Damage")
	bool bCanDamagePlayer;

	UPROPERTY(EditAnywhere, Category = "Damage")
	float Damage = 1.0;
	
	UPROPERTY(EditAnywhere, Category = "Damage")
	EDamageType DamageType = EDamageType::Default;

	UPROPERTY(EditAnywhere, Category = "Damage")
	UNiagaraSystem HitEffect;

	UPROPERTY(EditAnywhere)
	FName SmashableTeamName;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

		StartingTransform = MovableObject.GetWorldTransform();
		StartingPosition = StartingTransform.GetLocation();
		StartingRotation = StartingTransform.GetRotation();

		EndingTransform = EndPosition.GetWorldTransform();
		EndingPosition = EndingTransform.GetLocation();
		EndingRotation = EndingTransform.GetRotation();

		MoveAnimation.SetPlayRate(1.0 / AnimationDuration);
		MoveAnimation.BindUpdate(this, n"OnUpdate");
		MoveAnimation.BindFinished(this, n"OnFinished");

	}

	UFUNCTION()
	void Activate()
	{
		MoveAnimation.PlayFromStart();
	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{

		Root.SetWorldLocation(Math::Lerp(StartingPosition, EndingPosition, Alpha));
		Root.SetWorldRotation(FQuat::SlerpFullPath(StartingRotation, EndingRotation, Alpha));

		FHazeTraceSettings Trace = Trace::InitObjectType(EObjectTypeQuery::EnemyCharacter);
		Trace.UseShape(FHazeTraceShape::MakeFromComponent(Collision));
		FOverlapResultArray SmashResult = Trace.QueryOverlaps(Collision.WorldLocation);

		for (auto Smash : SmashResult.OverlapResults)
		{
			auto HealthComp = UBasicAIHealthComponent::Get(Smash.Actor);

			if (HealthComp != nullptr)
			{
				HealthComp.TakeDamage(Damage, DamageType, this);
			}
		}
	}

	
	UFUNCTION()
	void OnFinished()
	{
		OnReachedtDestination.Broadcast();
	}

}