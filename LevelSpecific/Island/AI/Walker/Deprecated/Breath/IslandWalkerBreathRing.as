class AIslandWalkerBreathRing : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	AHazeActor Owner;
	UIslandWalkerSettings Settings;
	private float CurrentRadius = 0;
	private int SegmentNum = 24;
	TArray<AIslandWalkerBreathRingSegment> Segments;

	UPROPERTY()
	TSubclassOf<AIslandWalkerBreathRingSegment> SegmentClass;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(Owner != nullptr)
			Settings = UIslandWalkerSettings::GetSettings(Owner);
		else
			Settings = UIslandWalkerSettings::GetSettings(this);
		
		for(int i = SegmentNum-1; i >= 0; i--)
		{
			AIslandWalkerBreathRingSegment Segment = SpawnActor(SegmentClass);
			Segments.Add(Segment);	
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		CurrentRadius += Settings.BreathRingExpansionSpeed * DeltaTime;

		for(int i = SegmentNum-1; i >= 0; i--)
		{
			float Degrees = (360.0 / SegmentNum) * i;
			FVector Direction = ActorForwardVector.RotateAngleAxis(Degrees, ActorUpVector);
			Segments[i].SetActorLocation(ActorLocation + Direction * CurrentRadius);
		}
		
		for (AHazePlayerCharacter CurPlayer : Game::GetPlayers())
		{			
			bool bDamagePlayer = false;
			float HorizontalDistance = GetHorizontalDistanceTo(CurPlayer);
			float VerticalDistance = Math::Abs(ActorUpVector.DotProduct(ActorLocation - CurPlayer.ActorCenterLocation));

			if (HorizontalDistance > CurrentRadius - Settings.BreathRingDamageWidth && HorizontalDistance < CurrentRadius + Settings.BreathRingDamageWidth)
				bDamagePlayer = true;
			if (VerticalDistance >= Settings.BreathRingDamageWidth)
				bDamagePlayer = false;
			if (bDamagePlayer && CurPlayer.HasControl())
			{
				auto UserComp = UIslandPlayerForceFieldUserComponent::Get(CurPlayer);
				if(UserComp != nullptr)
					UserComp.TakeDamagePoison(DeltaTime, 0.4, 1);
			}
		}

		if(CurrentRadius > Settings.BreathRingMaximumRadius)
		{
			for(AIslandWalkerBreathRingSegment Segment: Segments)
				Segment.Expire();
			DestroyActor();
		}
	}
}