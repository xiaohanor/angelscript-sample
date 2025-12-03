class ASanctuaryCipherBoard : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent HighlightMarker;

	UPROPERTY(DefaultComponent, Attach = HighlightMarker)
	UStaticMeshComponent HighlightMarkerMesh;

	UPROPERTY(DefaultComponent, Attach = HighlightMarker)
	UNiagaraComponent MarkerRibbonComp;

	UPROPERTY(EditAnywhere)
	TSubclassOf<ASanctuaryCipherLetter> LetterClass;

	TArray<ASanctuaryCipherLetter> Letters;
	TArray<int> LetterIndexes;
	TArray<float> LetterDistances;
	FHazeRuntimeSpline MessageSpline;

	float SplineDistance = 0.0;

	FHazeAcceleratedFloat AccSpeed;
	FHazeAcceleratedFloat AccMarkerScale;
	FVector MarkerScale;

	bool bPrintingMessage = false;
	FVector LastMovement;

	float NewMessageCooldown = 0.0;

	int MessageIndex = 0;
	TArray<FString> Messages;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AccSpeed.SnapTo(0.0);
		MarkerScale = HighlightMarkerMesh.GetWorldScale();
		SpawnLetters();
		Messages.Add(FString("  "));
		// Messages.Add(FString(" QWERTYUIOPASDFGHJKLZXCVBNM "));
		Messages.Add(FString(" HELP ME ZOE "));
		Messages.Add(FString(" I MISS YOU "));
		Messages.Add(FString(" FUCK THE OSCARS "));
	}

	private void SpawnLetters()
	{
		bool bStandingBoard = true;
		if (bStandingBoard)
		{
			float RowStep = 100.0;
			float ColumnStep = -100.0;

			for (int iColumn = 0; iColumn < 3; iColumn++)
			{
				for (int iRow = 0; iRow < 10; iRow++)
				{
					FVector RowLocation = ActorRightVector * RowStep * iColumn;
					FVector ColumnLocation = ActorUpVector * ColumnStep * iRow;

					AActor Letter = SpawnActor(LetterClass, ActorLocation + RowLocation + ColumnLocation, ActorRotation);
					Letters.Add(Cast<ASanctuaryCipherLetter>(Letter));
				}
			}

			FVector SpaceColumn = ActorUpVector * ColumnStep * 4.5;
			FVector SpaceRow = ActorRightVector * RowStep * 3.3;
			ASanctuaryCipherLetter Letter = Cast<ASanctuaryCipherLetter>(SpawnActor(LetterClass, ActorLocation + SpaceRow + SpaceColumn, ActorRotation));
			Letter.SetActorScale3D(FVector(1.5, 1.5, 1.5));
			Letters.Add(Letter);
		}
		else
		{
			float RowStep = -100.0;
			float ColumnStep = -100.0;

			for (int iRow = 0; iRow < 3; iRow++)
			{
				float ColumnLocation = ColumnStep * iRow;
				for (int iColumn = 0; iColumn < 10; iColumn++)
				{
					float RowLocation = RowStep * iColumn;
					AActor Letter = SpawnActor(LetterClass, ActorLocation + ActorRightVector * RowLocation + ActorUpVector * ColumnLocation, ActorRotation);
					Letters.Add(Cast<ASanctuaryCipherLetter>(Letter));
				}
			}
			ASanctuaryCipherLetter Letter = Cast<ASanctuaryCipherLetter>(SpawnActor(LetterClass, ActorLocation + ActorRightVector * RowStep * 4.5 + ActorUpVector * ColumnStep * 3.3, ActorRotation));
			Letter.SetActorScale3D(FVector(1.5, 1.5, 1.5));
			Letters.Add(Letter);	
		}
	}

	void PrintMessage(FString Message)
	{
		TArray<FVector> LetterPoints;
		LetterIndexes.Reset(Message.Len());
		LetterDistances.Reset(Message.Len());
		for (int iLetter = 0; iLetter < Message.Len(); ++iLetter)
		{
			FString NextLetter = Message.Mid(iLetter, 1);
			int AlphabetIndex = GetLetterIndex(NextLetter);
			LetterIndexes.Add(AlphabetIndex);
			FVector LetterLocation = Letters[AlphabetIndex].ActorLocation + ActorForwardVector * 10.0;
			const float MaxRandomOffset = 10.0;
			LetterLocation.Y += Math::RandRange(-MaxRandomOffset, MaxRandomOffset);
			LetterLocation.X += Math::RandRange(-MaxRandomOffset, MaxRandomOffset);

			LetterPoints.Add(LetterLocation);
		}

		MessageSpline.SetPoints(LetterPoints);

		for (int iPoint = 0; iPoint < MessageSpline.Points.Num(); ++iPoint)
		{
			LetterDistances.Add(MessageSpline.GetSplineDistanceAtSplinePointIndex(iPoint));
		}

		SplineDistance = 0.0;
		bPrintingMessage = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{

		NewMessageCooldown -= DeltaSeconds;
		if (NewMessageCooldown < 0.0)
		{
			FString NextMessage = Messages[MessageIndex];
			MessageIndex++;
			if (MessageIndex >= Messages.Num())
				MessageIndex = 0;
			PrintMessage(NextMessage);
			NewMessageCooldown = 2.1 * NextMessage.Len();
			NewMessageCooldown += 3.0;
		}

		//MessageSpline.DrawDebugSpline();
		if (bPrintingMessage)
		{
			AccMarkerScale.AccelerateTo(1.0, 0.5, DeltaSeconds);
			HighlightMarkerMesh.SetWorldScale3D(MarkerScale * AccMarkerScale.Value);

			AccSpeed.AccelerateTo(200.0, 1.0, DeltaSeconds);
			float PreviousDistance = SplineDistance;
			SplineDistance += DeltaSeconds * AccSpeed.Value;
			if (SplineDistance > MessageSpline.Length)
			{
				SplineDistance = MessageSpline.Length;
				bPrintingMessage = false;
			}
			FVector NewLocation = MessageSpline.GetLocationAtDistance(SplineDistance);
			LastMovement = NewLocation - HighlightMarker.WorldLocation;
			HighlightMarker.SetWorldLocation(NewLocation);

			for (int iLetter = 0; iLetter < LetterDistances.Num(); ++iLetter)
			{
				if (LetterDistances[iLetter] >= PreviousDistance && LetterDistances[iLetter] <= SplineDistance)
				{
					int LetterIndex = LetterIndexes[iLetter];
						if (iLetter == 0 || iLetter == LetterIndexes.Num() -1)
						continue;
					Letters[LetterIndex].StartHighlight();
					// Debug::DrawDebugSphere(Letters[LetterIndex].ActorLocation, 50.0, 12, ColorDebug::Red, 3.0, 1.0);

				}
			}
		}
		else
		{
			if (AccSpeed.Value > KINDA_SMALL_NUMBER)
			{
				AccSpeed.AccelerateTo(0.0, 0.1, DeltaSeconds);
				FVector DecelDelta = LastMovement.GetSafeNormal() * AccSpeed.Value * DeltaSeconds;
				HighlightMarker.SetWorldLocation(HighlightMarker.WorldLocation + DecelDelta);
			}
			AccMarkerScale.AccelerateTo(0.5, 0.5, DeltaSeconds);
			if (AccMarkerScale.Value > 0.5)
			{
				HighlightMarkerMesh.SetWorldScale3D(MarkerScale * AccMarkerScale.Value);
			}
		}
	}

	private int GetLetterIndex(FString Letter) const
	{
		if (Letter == "Q")
			return 0;
		if (Letter == "W")
			return 1;
		if (Letter == "E")
			return 2;
		if (Letter == "R")
			return 3;
		if (Letter == "T")
			return 4;
		if (Letter == "Y")
			return 5;
		if (Letter == "U")
			return 6;
		if (Letter == "I")
			return 7;
		if (Letter == "O")
			return 8;
		if (Letter == "P")
			return 9;
		if (Letter == "A")
			return 10;
		if (Letter == "S")
			return 11;
		if (Letter == "D")
			return 12;
		if (Letter == "F")
			return 13;
		if (Letter == "G")
			return 14;
		if (Letter == "H")
			return 15;
		if (Letter == "J")
			return 16;
		if (Letter == "K")
			return 17;
		if (Letter == "L")
			return 18;
		// if (Letter == " ")
		// 	return 19;
		if (Letter == "Z")
			return 20;
		if (Letter == "X")
			return 21;
		if (Letter == "C")
			return 22;
		if (Letter == "V")
			return 23;
		if (Letter == "B")
			return 24;
		if (Letter == "N")
			return 25;
		if (Letter == "M")
			return 26;
		if (Letter == ",")
			return 27;
		if (Letter == ".")
			return 28;
		// if (Letter == " ")
		// 	return 29;
		// if (Letter == " ")
		// 	return 30;

		return Letters.Num() -1; // Space and stuff
	}
};