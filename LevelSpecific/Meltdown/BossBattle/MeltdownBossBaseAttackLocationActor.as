class AMeltdownBossBaseAttackLocationActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent StartPosRoot;

	UPROPERTY(DefaultComponent, Attach = StartPosRoot)
	UStaticMeshComponent StartPosMesh;

	UPROPERTY(EditConst)
	FVector StartPos;

	UPROPERTY(EditAnywhere)
	FVector TargetPos;

	UPROPERTY(EditAnywhere)
	bool bDontDestroyOnFinish;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike AttackAnim;
	default AttackAnim.Duration = 5;
	default AttackAnim.Curve.AddDefaultKey(0,0);
	default AttackAnim.Curve.AddDefaultKey(1,1);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartPos = StartPosRoot.RelativeLocation;

		AttackAnim.BindUpdate(this,n"OnUpdate");
		AttackAnim.BindFinished(this, n"OnFinished");

	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		StartPosRoot.RelativeLocation = Math::Lerp(StartPos,TargetPos, Alpha);
	}

	UFUNCTION()
	void PlayFunction()
	{
		AttackAnim.Play();
	}

	UFUNCTION()
	void OnFinished()
	{
		if (bDontDestroyOnFinish != true)
		DestroyActor();
		
	}
}