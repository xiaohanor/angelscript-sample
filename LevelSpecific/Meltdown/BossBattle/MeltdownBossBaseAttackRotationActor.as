class AMeltdownBossBaseAttackRotationActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent StartPosRoot;

	UPROPERTY(DefaultComponent, Attach = StartPosRoot)
	UStaticMeshComponent StartPosMesh;



	FRotator StartPos;

	UPROPERTY(EditAnywhere)
	float TargetRotation;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike AttackAnim;
	default AttackAnim.Duration = 5;
	default AttackAnim.Curve.AddDefaultKey(0,0);
	default AttackAnim.Curve.AddDefaultKey(5,1);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartPos = StartPosRoot.RelativeRotation;


		AttackAnim.BindUpdate(this,n"OnUpdate");
		AttackAnim.BindFinished(this, n"OnFinished");

	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		StartPosRoot.RelativeRotation = FQuat::Slerp(StartPos.Quaternion(), FRotator(0, TargetRotation, 0).Quaternion(), Alpha).Rotator();
	}

	UFUNCTION()
	void PlayFunction()
	{
		AttackAnim.PlayFromStart();
	}

	UFUNCTION()
	void OnFinished()
	{
		DestroyActor();
	}
}