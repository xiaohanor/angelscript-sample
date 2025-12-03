event void FSandHandHit();

class ASandHadSwingingTrigger : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UFauxPhysicsAxisRotateComponent AxisRotateComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UArrowComponent Arrow;

	UPROPERTY(DefaultComponent, Attach = AxisRotateComp)
	UStaticMeshComponent SwingMeshComp;

	UPROPERTY(DefaultComponent, Attach = AxisRotateComp)
	USandHandResponseComponent ResponseComp;

	UPROPERTY(EditInstanceOnly)
	ASandHadSwingingTrigger OtherSwingingTrigger;

	UPROPERTY(EditInstanceOnly)
	AKineticRotatingActor LeftDoor;

	UPROPERTY(EditInstanceOnly)
	AKineticRotatingActor RightDoor;

	float HitTime;
	AHazePlayerCharacter HitByPlayer;
	private bool bIsOpen = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ResponseComp.OnSandHandHitEvent.AddUFunction(this, n"SandHandHit");
	}

	UFUNCTION(BlueprintEvent)
	private void SandHandHit(FSandHandHitData HitData)
	{
		HitTime = Time::GameTimeSeconds;
		HitByPlayer = HitData.Caster;
		AxisRotateComp.ApplyImpulse(HitData.SandHandProjectile.ActorLocation, Arrow.ForwardVector * 1000);

		if(bIsOpen)
			return;

		if(!WasBothHitRecently())
			return;

		if(!WasHitByDifferentPlayers())
			return;

		if(HasControl())
			CrumbOpen();
	}

	UFUNCTION(CrumbFunction)
	void CrumbOpen()
	{
		if(bIsOpen)
			return;

		LeftDoor.ActivateForward();
		RightDoor.ActivateForward();

		bIsOpen = true;
	}

	private bool WasBothHitRecently() const
	{
		if(Time::GetGameTimeSince(HitTime) > 2)
			return false;

		if(Time::GetGameTimeSince(OtherSwingingTrigger.HitTime) > 2)
			return false;

		return true;
	}

	private bool WasHitByDifferentPlayers() const
	{
		if(HitByPlayer == nullptr || OtherSwingingTrigger.HitByPlayer == nullptr)
			return false;
		
		return HitByPlayer != OtherSwingingTrigger.HitByPlayer;
	}
}
