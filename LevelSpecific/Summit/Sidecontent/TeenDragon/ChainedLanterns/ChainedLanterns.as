class AChainedLanterns : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditInstanceOnly)
	ANightQueenChain MetalChain;

	UPROPERTY(EditAnywhere)
	UHazeAudioEvent Event;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 55000.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	FVector WindDirection = FVector::ForwardVector;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float WindFrequency = 0.45;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float WindRotateMaxDegrees = 7.5;
	
	UPROPERTY(EditAnywhere, Category = "Settings")
	float SidewaysFrequency = 0.25;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float SidewaysRotateMax = 2.0;

	bool bChainMelted = false;

	FRotator ChainStartRotation;

	float UpForce = 0.0;
	float TargetUpForce = 300.0; 
	float WindForce = 0.0;
	float TargetWindForce = 150.0;

	float ActorHash;

	FVector PreviousLocation;
	FVector CurrentVelocity;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MetalChain.DetachFromActor(EDetachmentRule::KeepWorld);
		MetalChain.OnChainMelted.AddUFunction(this, n"OnChainMelted");
		AttachToActor(MetalChain, AttachmentRule = EAttachmentRule::KeepWorld);
		ChainStartRotation = MetalChain.ActorRotation;

		TArray<UPrimitiveComponent> Primitives = GetComponentsByClass(UPrimitiveComponent);
		for(auto Primitive : Primitives)
		{
			Primitive.RemoveTag(n"Walkable");
		}

		ActorHash = Name.Hash;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bChainMelted)
		{
			UpForce = Math::FInterpConstantTo(UpForce, TargetUpForce, DeltaSeconds, TargetUpForce / 3);
			WindForce = Math::FInterpConstantTo(WindForce, TargetWindForce, DeltaSeconds, TargetWindForce / 6);
			ActorLocation += FVector::UpVector * UpForce * DeltaSeconds;
			ActorLocation += GetWindDirection() * WindForce * DeltaSeconds;
		}
		else
		{
			FVector ChainUp = FVector::UpVector;
			float WindAmount = (Math::PerlinNoise1D((Time::GameTimeSeconds * WindFrequency) + (ActorHash%10000)) * 0.5) + 0.7;
			float RotateDegrees = WindRotateMaxDegrees * WindAmount;

			FVector WindDir = GetWindDirection();
			FVector AngleAxis = WindDir.CrossProduct(FVector::UpVector);
			ChainUp = ChainUp.RotateAngleAxis(-RotateDegrees, AngleAxis);

			float SidewaysAmount = Math::PerlinNoise1D((Time::GameTimeSeconds * SidewaysFrequency) + (ActorHash%10000));
			float SidewaysDegrees = SidewaysRotateMax * SidewaysAmount;
			ChainUp = ChainUp.RotateAngleAxis(SidewaysDegrees, WindDir);

			FRotator ChainRotation = FRotator::MakeFromZY(-ChainUp, ChainStartRotation.RightVector);
			MetalChain.RootComponent.WorldRotation = ChainRotation;

			TEMPORAL_LOG(this)
				.DirectionalArrow("Chain Up", ActorLocation, ChainUp * 500, 20, 5000, FLinearColor::Blue)
				.Rotation("Chain Rotation", ChainRotation, ActorLocation, 500)
				.Value("Wind Amount", WindAmount)
				.Value("Rotate Degrees", RotateDegrees)
			;

			CurrentVelocity = (ActorLocation - PreviousLocation) / DeltaSeconds;
			PreviousLocation = ActorLocation;
		}
	}

	UFUNCTION()
	private void OnChainMelted(ANightQueenChain Chain)
	{
		bChainMelted = true;

		UpForce = CurrentVelocity.DotProduct(FVector::UpVector);
		WindForce = CurrentVelocity.DotProduct(GetWindDirection());
		FHazeAudioFireForgetEventParams AudioParams;
		AudioParams.AttenuationScaling = 10000;
		AudioParams.AttachComponent = RootComponent;
		AudioComponent::PostFireForget(Event, AudioParams);
	}

	private FVector GetWindDirection() const
	{
		return ActorTransform.TransformVectorNoScale(WindDirection.GetSafeNormal());
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		FVector WindDirectionLocation = ActorLocation + GetWindDirection() * 500;
		Debug::DrawDebugArrow(ActorLocation, WindDirectionLocation, 5000, FLinearColor::Red, 20);
		Debug::DrawDebugString(WindDirectionLocation + FVector::UpVector * 50, "Wind Direction", FLinearColor::Red);
	}
#endif
};