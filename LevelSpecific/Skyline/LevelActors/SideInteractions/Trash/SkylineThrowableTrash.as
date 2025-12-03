class ASkylineThrowableTrash : AWhipSlingableObject
{
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent TrashMesh;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	default bUseFocusLocation = false;

	void OnThrown(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, FHitResult HitResult, FVector Impulse) override
	{
		FVector OverrideImpulse = Impulse;
		TListedActors<ASkylineTrashcan> TrashCans;
		if (TrashCans.Num() > 0)
		{
			ASkylineTrashcan TrashCan = TrashCans.Single;
			if (GetOverrideDirectionToTrashCan(OverrideImpulse, TrashCan.WhipAutoAimComp))
				TrashCan.IncomingTrashes.Add(this);
			else if (GetOverrideDirectionToTrashCan(OverrideImpulse, TrashCan.WhipAutoAimBackComp))
				TrashCan.IncomingTrashes.Add(this);
			if (TrashCan.IncomingTrashes.Contains(this))
				HomingProjectileComp.Target = TrashCan;
		}
		//Debug::DrawDebugLine(ActorLocation, ActorLocation + OverrideImpulse, Duration = 5.0);
		Super::OnThrown(UserComponent, TargetComponent, HitResult, OverrideImpulse);
	}

	bool GetOverrideDirectionToTrashCan(FVector& OutImpulse, UGravityWhipSlingAutoAimComponent AutoAimComp)
	{
		FVector ToTrashCan = (AutoAimComp.WorldLocation - ActorLocation);
		if (ToTrashCan.Size() > AutoAimComp.MaximumDistance)
			return false;

		float ToTrashCanDotProduct = ToTrashCan.GetSafeNormal().DotProduct(OutImpulse.GetSafeNormal());
		if (Math::DotToDegrees(ToTrashCanDotProduct) < AutoAimComp.AutoAimMaxAngle)
		{
			OutImpulse = ToTrashCan.GetSafeNormal() * OutImpulse.Size();
			return true;
		}

		return false;
	}
};