class AMeltdownBossBaseAttackInverseScaleActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent StartPosRoot;

	UPROPERTY(DefaultComponent, Attach = StartPosRoot)
	UStaticMeshComponent StartPosMesh;

	UPROPERTY(EditAnywhere)
	bool bDontDestroyOFinish;

	FVector StartPos;

	FVector TargetPos;


	UPROPERTY(EditAnywhere)
	float DesiredScaleX = 100.0;

	UPROPERTY(EditAnywhere)
	float DesiredScaleY = 100.0;

	UPROPERTY(EditAnywhere)
	float DesiredScaleZ = 0.0;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike AttackAnim;
	default AttackAnim.Duration = 5;
	default AttackAnim.Curve.AddDefaultKey(0,0);
	default AttackAnim.Curve.AddDefaultKey(5,1);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartPos = FVector(DesiredScaleX, DesiredScaleY, DesiredScaleZ);
		TargetPos = ActorRelativeScale3D;

		AttackAnim.BindUpdate(this,n"OnUpdate");
		AttackAnim.BindFinished(this, n"OnFinished");
	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		ActorRelativeScale3D = Math::Lerp(StartPos,TargetPos, Alpha);
	}

	UFUNCTION()
	void PlayFunction()
	{
		AttackAnim.PlayFromStart();
	}

	UFUNCTION()
	void OnFinished()
	{
		if (bDontDestroyOFinish != true)
		DestroyActor();
	}

	UFUNCTION()
	void ManualDestroy()
	{
		DestroyActor();
	}
}