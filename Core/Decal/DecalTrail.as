// Spawns decals as the it moves around.
class UDecalTrailComponent : USceneComponent
{
	/** The decal has a box around it to figure where it should paint the decal. So this variable basically determines how close 
	 * to the surface the component needs to be for it to start drawing stuff on the surface.
	 */
	UPROPERTY(EditAnywhere, DisplayName = "Decal Height")
	float DecalWidth = 25;

	/** how often,  distance wise, the component should spawn a new decal when its moving. */
	UPROPERTY(EditAnywhere)
	float DecalLength = 100;

	/** this scales the width of the decal trail. stretches it. */
	UPROPERTY(EditAnywhere, DisplayName = "Decal Width")
	float DecalHeight = 25;

	UPROPERTY(EditAnywhere)
	float Overlap = 0.0;
	
	UPROPERTY(EditAnywhere)
	UMaterialInterface DecalMaterial;

	UPROPERTY(EditAnywhere)
	int MaxDecals = 100;
	
	UPROPERTY(EditAnywhere)
	float DecalLifetime = 0.0;

	UPROPERTY(EditAnywhere)
	FVector SnapLocation;

	TArray<UDecalComponent> SpawnedDecals = TArray<UDecalComponent>();
	TArray<int> SpawnedDecalIndexes = TArray<int>();
	TArray<float> SpawnedDecalFadeValue = TArray<float>();
	
	UPROPERTY()
	UDecalComponent CurrentDecal;

	UPROPERTY()
	UMaterialInstanceDynamic CurrentDecalMaterial;

	bool bSpawnDecals = true;

	UHazeSplineComponent SplineComponent;
	
	float ProgressAlongSpline = 0;

	int decalIndex = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SnapLocation = GetTrailLocation();
		SpawnedDecals.Empty();
		SpawnedDecalIndexes.Empty();
		SpawnedDecalFadeValue.Empty();
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		for (auto Decal : SpawnedDecals)
		{
			if (Decal != nullptr)
				Decal.DestroyComponent(Decal);
		}
	}

	float GlobalDecalFade = 0;
	float GlobalDecalFadeTotal = 0;
	// Removes all spawned decals
	UFUNCTION()
	void Clear(float FadeTime = 0.0)
	{
		// This function was broken before, 
		//GlobalDecalFade = FadeTime + 0.001;
		//GlobalDecalFadeTotal = GlobalDecalFade;
	}
	bool bClearCalled = false;
	UFUNCTION()
	void ClearNew(float FadeTime = 0.0)
	{
		// This function was broken before, 
		GlobalDecalFade = FadeTime + 0.001;
		GlobalDecalFadeTotal = GlobalDecalFade;
		bClearCalled = true;
	}
	
	// When clear is called this function is used to slowly fade the whole thing out.
	void GlobalFade(float DeltaTime)
	{
		if(GlobalDecalFade > 0) // If it's larger than 0, fade down.
		{
			GlobalDecalFade -= DeltaTime;
			float Opacity = GlobalDecalFade / GlobalDecalFadeTotal;
			
			for (UDecalComponent DecalComponent : SpawnedDecals)
			{
				if(DecalComponent == nullptr)
					continue;
				
				FLinearColor Color = DecalComponent.DecalColor;
				Color.B = Opacity;
				DecalComponent.SetDecalColor(Color);
			}
		}
		else if(GlobalDecalFade < 0) // on the frame where it went below 0, set it to exactly 0 so it stops changing.
		{
			GlobalDecalFade = 0;
			for (int i = 0; i < SpawnedDecals.Num(); i++)
			{
				if(SpawnedDecals[i] != nullptr)
					SpawnedDecals[i].DestroyComponent(SpawnedDecals[i]);
			}
		}
	}
	
	// Each tick we want to update the parameter for the decals in our array, so first decal if 1.0 and last 0.0
	void DecayOverTrail(float Decay)
	{
		if (SpawnedDecals.Num() == 0)
			return;		

		float Value = 1.0 / MaxDecals; // The value to increment for each decal,
		float CurrentValue = 1.0; // Starting value for 'last' decal in queue,
		float PreviousValue = 1.0;

		// Iterate over spawned decals, going from last spawned to earliest available,
		for (int i = SpawnedDecals.Num() - 1; i >= 0; i--)
		{
			if (SpawnedDecals[i] == nullptr)
				continue;
			
			float Offset = 1.0 - GetTrailLocation().Distance(SnapLocation) / DecalLength;

			FLinearColor Color = SpawnedDecals[i].DecalColor;
			
			float FadeValue = SpawnedDecalFadeValue[i];
			FadeValue = Math::Max(0.0, FadeValue - (Decay / DecalLifetime));
			SpawnedDecalFadeValue[i] = FadeValue;
			Color.R = SpawnedDecalIndexes[i];
			Color.G = (CurrentValue + Value * Offset) * FadeValue;
			Color.B = PreviousValue;
			SpawnedDecals[i].SetDecalColor(Color);

			PreviousValue = Color.G;			
			CurrentValue = Math::Max(0.0, CurrentValue - Value);
		}
	}

	FVector GetTrailLocation()
	{
		if(SplineComponent != nullptr)
			return SplineComponent.GetWorldLocationAtSplineDistance(ProgressAlongSpline);
		else
			return GetWorldLocation();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(DecalMaterial == nullptr)
			return;

		if(bSpawnDecals)
		{
			if(CurrentDecalMaterial == nullptr)
			{
				CurrentDecal = Decal::SpawnDecalAtLocation(DecalMaterial, FVector::OneVector, FVector::ZeroVector);
				decalIndex++;
				CurrentDecalMaterial = CurrentDecal.CreateDynamicMaterialInstance();
				SpawnedDecals.Add(CurrentDecal);
				SpawnedDecalIndexes.Add(decalIndex);
				SpawnedDecalFadeValue.Add(0);
			}

			if(CurrentDecal != nullptr)
			{
				FVector CenterPoint = (SnapLocation + GetTrailLocation()) * 0.5;
				FVector Forward = GetTrailLocation() - SnapLocation;
				float Distance = Forward.Size();
				Forward.Normalize();

				FRotator DecalRotation = FRotator::MakeFromZX(Forward, -GetWorldRotation().GetUpVector());

				CurrentDecal.SetWorldLocation(CenterPoint);
				CurrentDecal.SetWorldRotation(DecalRotation);
				CurrentDecal.SetRelativeScale3D(FVector(DecalWidth, DecalHeight, Distance * 0.5 * (Overlap + 1.0)));
				
				FLinearColor Color = CurrentDecal.DecalColor;
				Color.A = Distance / DecalLength;
				CurrentDecal.SetDecalColor(Color);
			}

			if(GetTrailLocation().Distance(SnapLocation) > DecalLength)
			{
				SnapLocation = GetTrailLocation();
				CurrentDecal = Decal::SpawnDecalAtLocation(DecalMaterial, FVector::OneVector, FVector::ZeroVector);
				decalIndex++;
				CurrentDecalMaterial = CurrentDecal.CreateDynamicMaterialInstance();
				SpawnedDecals.Add(CurrentDecal);
				SpawnedDecalIndexes.Add(decalIndex);
				SpawnedDecalFadeValue.Add(1);
				if(SpawnedDecals.Num() > MaxDecals)
				{
					UDecalComponent LastDecal = SpawnedDecals[0];
					if(LastDecal != nullptr)
						LastDecal.DestroyComponent(LastDecal);
					SpawnedDecals.RemoveAt(0);
					SpawnedDecalIndexes.RemoveAt(0);
					SpawnedDecalFadeValue.RemoveAt(0);
				}
			}
		}
		else
		{
			SnapLocation = GetTrailLocation();
		}


		// Update existing decals,
		if(DecalLifetime > 0.0)
			DecayOverTrail(DeltaTime);
		
		if(bClearCalled)
			GlobalFade(DeltaTime);
	}

	UFUNCTION(BlueprintCallable)
	void SetSpawningEnabled(bool bEnable)
	{
		bSpawnDecals = bEnable;
		
		if(bEnable)
			SnapLocation = GetTrailLocation();
	}
}