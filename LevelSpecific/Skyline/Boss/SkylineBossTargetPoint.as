class ASkylineBossTargetPoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UBillboardComponent BillboardComponent;
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		JoinTeam(n"SkylineBossTargetPoints");
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		LeaveTeam(n"SkylineBossTargetPoints");
	}	
}