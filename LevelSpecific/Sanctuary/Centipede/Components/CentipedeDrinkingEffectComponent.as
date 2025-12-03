
enum ECentipedeDrinkingDirection
{
	Forward,
	Backwards,
	None,
};

class UCentipedeDrinkingEffectComponent : UActorComponent
{
	ACentipede Centipede;
	UPlayerCentipedeComponent PlayerCentipedeComponent;

	TArray<FName> ParameterNames;

	ECentipedeDrinkingDirection Direction;

	UPROPERTY(EditAnywhere)
	float Strength = 50;

	UPROPERTY(EditAnywhere)
	float BulgeMoveSpeed = 0.5;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Centipede = Cast<ACentipede>(Owner);
		for (int i = 0; i < Centipede.Mesh.NumMaterials; i++)
		{
			Centipede.Mesh.CreateDynamicMaterialInstance(i);
		}
		PlayerCentipedeComponent = UPlayerCentipedeComponent::Get(Game::Mio);
		ParameterNames.Add(n"Bulge0");
		ParameterNames.Add(n"Bulge1");
		ParameterNames.Add(n"Bulge2");
		ParameterNames.Add(n"Bulge3");
		ParameterNames.Add(n"Bulge4");
		ParameterNames.Add(n"Bulge5");
		ParameterNames.Add(n"Bulge6");
		ParameterNames.Add(n"Bulge7");
		ParameterNames.Add(n"Bulge8");
		ParameterNames.Add(n"Bulge9");
	}

	TMap<FInstigator, FVector> Bulges;

	void BulgeAdd(FInstigator Instigator)
	{
		Bulges.Add(Instigator, FVector(0, 0, 0));
	}
	void BulgeUpdate(FInstigator Instigator, FVector WorldLocation)
	{
		Bulges[Instigator] = WorldLocation;
	}
	void BulgeRemove(FInstigator Instigator)
	{
		Bulges.Remove(Instigator);
	}

	float CurrentStrength = 0;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Centipede.bIsControlledByCutscene)
			return;

		if(PlayerCentipedeComponent.bBitingWater)
		{
			Direction = ECentipedeDrinkingDirection::Forward;
			CurrentStrength = Math::Lerp(CurrentStrength, Strength, DeltaSeconds * 2.0);
		}
		else if(PlayerCentipedeComponent.bShootingWater)
		{
			Direction = ECentipedeDrinkingDirection::Backwards;
			CurrentStrength = Math::Lerp(CurrentStrength, Strength, DeltaSeconds * 2.0);
		}
		else
		{
			Direction = ECentipedeDrinkingDirection::None;
			CurrentStrength = Math::Lerp(CurrentStrength, 0, DeltaSeconds * 2.0);
		}
		
		for (int i = 0; i < Centipede.Mesh.NumMaterials; i++)
		{
			int DrinkingBulgeCount = 5;
			for (int J = 0; J < DrinkingBulgeCount; J++) // 0-4
			{
				float T = float(J) / float(DrinkingBulgeCount-1);

				float Fraction = T + Time::GameTimeSeconds * BulgeMoveSpeed * (Direction == ECentipedeDrinkingDirection::Forward ? 1 : -1);
				Fraction = Math::Frac(Fraction);

				float FractionBasedCurrentStrength = (1.0 - Math::Pow(Math::Abs((Fraction * 2.0) - 1.0), 2.0));

				FVector Pos = Centipede.GetLocationAtBodyFractionForHeadPlayer(Fraction, Game::Mio.Player);
				Centipede.Mesh.SetColorParameterValueOnMaterialIndex(i, ParameterNames[J], FLinearColor(Pos, FractionBasedCurrentStrength * CurrentStrength));
			}

			int MortarBulgeCount = 5;
			int J = 0;
			for (auto Element : Bulges)
			{
				Centipede.Mesh.SetColorParameterValueOnMaterialIndex(i, ParameterNames[J], FLinearColor(Element.Value, 60));
				J++;
				if(J >= MortarBulgeCount)
					break;
			}
		}
	}
};
