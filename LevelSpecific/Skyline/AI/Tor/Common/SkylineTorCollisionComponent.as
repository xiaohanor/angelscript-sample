class USkylineTorCollisionComponent : UActorComponent
{
	UBasicAICharacterMovementComponent MoveComp;
	ASplineActor BoundsSpline;
	private TInstigated<bool> bEnable;
	ASkylineTorCenterPoint CenterPoint;
	bool bIsEnabled;
	bool bWasOutside;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		BoundsSpline = TListedActors<ASkylineTorReferenceManager>().Single.ArenaBoundsSpline;
		CenterPoint = TListedActors<ASkylineTorCenterPoint>().Single;
	}

	void EnableArenaBounds(FInstigator Instigator)
	{
		bEnable.Apply(true, Instigator);
	}

	void ClearArenaBounds(FInstigator Instigator)
	{
		bEnable.Clear(Instigator);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector ClosestPoint = BoundsSpline.Spline.GetClosestSplineWorldLocationToWorldLocation(Owner.ActorLocation);
		FVector Direction = (ClosestPoint - CenterPoint.ActorLocation).GetSafeNormal2D();
		bool bOutside = Direction.DotProduct((ClosestPoint - Owner.ActorLocation).GetSafeNormal2D()) < 0;

		if(!bIsEnabled && (bEnable.Get() && !bOutside))
		{
			TArray<ASplineActor> Splines;
			Splines.Add(BoundsSpline);
			MoveComp.ApplySplineCollision(Splines, this);
			bIsEnabled = true;
			bWasOutside = bOutside;
		}
		
		if(bIsEnabled && (!bEnable.Get() || bOutside))
		{
			MoveComp.ClearSplineCollision(this);
			bIsEnabled = false;
			bWasOutside = bOutside;
		}
	}
}