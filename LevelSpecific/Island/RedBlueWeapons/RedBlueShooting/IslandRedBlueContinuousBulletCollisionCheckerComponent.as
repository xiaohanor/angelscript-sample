struct FIslandRedBlueContinuousBulletCollisionCheckingData
{
	FVector BulletLocation;
	uint FrameNumber;
}

/* Place this on actors that move that red blue bullets should never be able to pass through */
class UIslandRedBlueContinuousBulletCollisionCheckingComponent : UActorComponent
{
	// Bullets trace from their current location to their target location for that frame before moving to check for hits
	// If something is in front of the bullet when the bullet move is performed but far enough that the bullet didn't actually enter it's collider,
	// and then after the bullet has moved, the object is moved so far that it's entire collider will move past the bullet, the bullet wont actually hit
	// the object when the next move is performed. This gets worse with fast moving bullets/objects, low framerate and with objects that have a very thin collider
	// (such as force fields), this component will fix that by checking if an object has passed through the bullet. This is more expensive though so use it only when required.
	//
	//  (Post bullet move, pre force field move)	  (same frame, post force field move)
	//					| 										|	┊
	//					|										| 	┊
	// Bullet --->  ◌ ο	| <--- Force field						| ο ┊ <--- Force field (that has moved to the left)
	// (after moving	|										| ^	┊
	// to the right)	|										| |	┊
	//														  Bullet (hasn't moved again since last time)

	private uint64 OnMovedDelegateHandle = 0;
	private FTransform PreviousTransform;
	private bool bInitialized = false;
	private ECollisionChannel TraceChannel;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TraceChannel = UIslandRedBlueWeaponSettings::GetSettings(Game::Mio).TraceChannel;
		Init();
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		Init();
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		Unbind();
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		Unbind();
	}

	private void Init()
	{
		if(bInitialized)
			Unbind();

		bInitialized = true;
		OnMovedDelegateHandle = SceneComponent::BindOnSceneComponentMoved(Owner.RootComponent, FOnSceneComponentMoved(this, n"OnMoved"));
		PreviousTransform = Owner.ActorTransform;
	}

	private void Unbind()
	{
		SceneComponent::UnbindOnSceneComponentMoved(Owner.RootComponent, OnMovedDelegateHandle);
		bInitialized = false;
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnMoved(USceneComponent MovedComponent, bool bIsTeleport)
	{
		FBox Bounds = Owner.GetActorLocalBoundingBox(true);

		TArray<AIslandRedBlueWeaponBullet> Bullets;
		{
			TListedActors<AIslandRedBlueWeaponBullet> ListedBullets;
			Bullets = ListedBullets.GetArray();
		}

		for(AIslandRedBlueWeaponBullet Bullet : Bullets)
		{
			FHitResult Hit;
			bool bCheckedCollision = false;
			if(!Bullet.ActorLocation.Equals(Bullet.PreviousLocation))
			{
				bCheckedCollision = TryCheckCollision(Bullet, Bounds, Hit);
			}

			TemporalLog(Bullet, Bounds, bCheckedCollision, Hit);
		}
		
		PreviousTransform = Owner.ActorTransform;
	}

	// Will return true if we actually checked collision
	private bool TryCheckCollision(AIslandRedBlueWeaponBullet Bullet, FBox ActorLocalBounds, FHitResult& OutHit)
	{
		FVector PreviousRelativeBulletLocation = PreviousTransform.InverseTransformPosition(Bullet.PreviousLocation);
		FVector CurrentRelativeBulletLocation = Owner.ActorTransform.InverseTransformPosition(Bullet.ActorLocation);
		
		bool bIntersect = Math::LineBoxIntersection(ActorLocalBounds, PreviousRelativeBulletLocation, CurrentRelativeBulletLocation);
		if(bIntersect)
		{
			FVector WorldPreviousBulletLocation = Owner.ActorTransform.TransformPosition(PreviousRelativeBulletLocation);
			Bullet.TraceForHits(WorldPreviousBulletLocation, Bullet.ActorLocation, "ContinuousCollision");
			return true;
		}

		return false;
	}

	private void TemporalLog(AIslandRedBlueWeaponBullet Bullet, FBox ActorLocalBounds, bool bCheckedCollision, FHitResult CheckCollisionHit)
	{
#if EDITOR
			int Index = -1;
			FString BulletNameString = Bullet.Name.ToString();
			bool bSuccessful = BulletNameString.FindLastChar('_', Index);
			FString SortingNumber = bSuccessful ? BulletNameString.Right(BulletNameString.Len() - Index - 1) : "";

			TEMPORAL_LOG(this)
			.Point(f"{SortingNumber}#{Bullet.Name};Location", Bullet.ActorLocation, 20.0, FLinearColor::Green)
			.Point(f"{SortingNumber}#{Bullet.Name};Actor Location", Owner.ActorLocation)
			.Box(f"{SortingNumber}#{Bullet.Name};Actor Bounding Box", Owner.ActorTransform.TransformPosition(ActorLocalBounds.Center), ActorLocalBounds.Extent * Owner.ActorScale3D, Owner.ActorRotation)
			.Line(f"{SortingNumber}#{Bullet.Name};Bounding Box Intersection Line", Owner.ActorTransform.TransformPosition(PreviousTransform.InverseTransformPosition(Bullet.PreviousLocation)), Bullet.ActorLocation);

			if(bCheckedCollision)
				TEMPORAL_LOG(this).HitResults(f"{SortingNumber}#{Bullet.Name};Bullet Trace Hit", CheckCollisionHit, FHazeTraceShape::MakeLine());
#endif
	}
}