class ASkylineBossPlayerRespawnPoint : ARespawnPoint
{
	UPROPERTY(EditAnywhere)
	float Distance = 29000.0;

	UPROPERTY(EditAnywhere)
	float Angle = 70.0;

	UFUNCTION(BlueprintOverride, Meta = (NoSuperCall))
	void ConstructionScript() override
	{
		UpdatePlayerSpawnLocations();

        // Hide the second position if not relevant
        bool bShouldHideSecond = !bCanMioUse || !bCanZoeUse;
        if (bShouldHideSecond != bIsSecondHidden)
        {
            if (bShouldHideSecond)
            {
                StoredSecondPosition = SecondPosition;
                SecondPosition = FTransform(FVector(99999, 99999, 99999));
            }
            else
            {
                SecondPosition = StoredSecondPosition;
            }
            bIsSecondHidden = bShouldHideSecond;
        }

        // Classify the main and secondary transform
#if EDITOR
		const bool bShouldSnap = bSnapToGround || bSnapToSpline;
		if (!bShouldSnap)
			ResetPlayerSpawnLocation();
		else if (!Editor::IsCooking() && Level.IsVisible() && Editor::IsSelected(this))
			UpdatePlayerSpawnLocation();
#endif

        // Make editor visualizers
        if (bCanMioUse)
            CreateForPlayer(EHazePlayer::Mio, FinalSpawnPositions[EHazePlayer::Mio]);
        if (bCanZoeUse)
            CreateForPlayer(EHazePlayer::Zoe, FinalSpawnPositions[EHazePlayer::Zoe]);
 	}

	void UpdatePlayerSpawnLocations()
	{
		FTransform MioTransform;
		FTransform ZoeTransform;

		if (AttachParentActor == nullptr)
			return;

		MioTransform.Location = (FVector::ForwardVector * Distance).RotateAngleAxis(Angle, FVector::UpVector);
		MioTransform.Rotation = (-MioTransform.Location).ToOrientationQuat();

		ZoeTransform.Location = (FVector::ForwardVector * Distance).RotateAngleAxis(-Angle, FVector::UpVector);
		ZoeTransform.Rotation = (-ZoeTransform.Location).ToOrientationQuat();

		ActorTransform = MioTransform * AttachParentActor.ActorTransform;
		SecondPosition = (ZoeTransform * AttachParentActor.ActorTransform).GetRelativeTransform(ActorTransform);	
	}
};