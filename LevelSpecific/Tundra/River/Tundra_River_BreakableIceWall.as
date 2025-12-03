event void FBreakableIceWallEvent();

class ATundra_River_BreakableIceWall : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = MeshComp)
	UTundraTreeGuardianRangedShootTargetable LaunchSphereHitComp;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem BreakEffect;

	UPROPERTY(EditAnywhere)
	int TimesToHit = 2;

	UPROPERTY()
	FBreakableIceWallEvent OnWallBroken;

	UPROPERTY()
	FBreakableIceWallEvent OnWallHit;

	int TimesHit = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LaunchSphereHitComp.OnHit.AddUFunction(this, n"HitByLaunchSphere");
	}

	UFUNCTION()
	private void HitByLaunchSphere()
	{
		TimesHit++;
		OnWallHit.Broadcast();
		Niagara::SpawnOneShotNiagaraSystemAtLocation(BreakEffect, ActorLocation);

		if(TimesHit == TimesToHit)
		{
			ActorHiddenInGame = true;
			MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
			OnWallBroken.Broadcast();
			LaunchSphereHitComp.Disable(this);
		}
	}
};