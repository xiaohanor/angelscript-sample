UCLASS(Abstract)
class UDragonSwordCombatCrosshairWidget : UTargetableWidget
{
	UDragonSwordCombatUserComponent CombatComp;
	UPlayerTargetablesComponent TargetablesComp;

	UPROPERTY(Meta = (BindWidget))
	UCanvasPanel EnemyCanvas;

	UPROPERTY(Meta = (BindWidget))
	UWidget CrosshairWidget;

	UPROPERTY(BlueprintReadOnly)
	FText TargetName;

	private FString TargetString;
	private FString DistortedText;
	private TArray<int> DistortedIndices;
	private UDragonSwordCombatTargetComponent CurrentTarget;
	private TArray<int16> Characters;
	private bool bCurrentTargetHasName = false;
	private float LastChangedTime = 0;

	const float REVEAL_DURATION = 0.2;

	bool bWasVisible = false;	// Delay visibility by 1 frame to prevent the crosshair being visible when it shouldn't be

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		CombatComp = UDragonSwordCombatUserComponent::Get(Player);
		TargetablesComp = UPlayerTargetablesComponent::Get(Player);

		GenerateCharactersArray();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		UDragonSwordCombatTargetComponent Target = Cast<UDragonSwordCombatTargetComponent>(TargetablesComp.GetPrimaryTargetForCategory(DragonSwordCombat::TargetableCategory));

		if(Target != CurrentTarget)
		{
			OnTargetChanged(Target);
		}

		if (CurrentTarget != nullptr && bCurrentTargetHasName)
		{
			if(DistortedIndices.Num() > 0)
			{
				float TimeSinceLastChanged = Time::GameTimeSeconds - LastChangedTime;
				int DesiredRevealedCharacters = int(Math::Saturate(TimeSinceLastChanged / REVEAL_DURATION) * DistortedText.Len());
				while(DistortedText.Len() - DistortedIndices.Num() < DesiredRevealedCharacters)
				{
					DistortedIndices.RemoveAtSwap(Math::RandRange(0, DistortedIndices.Num() - 1));
				}
			}

			FString DisplayText = TargetString;
			for(int i = 0; i < TargetString.Len(); i++)
			{
				if(DistortedIndices.FindIndex(i) >= 0)
					DisplayText[i] = DistortedText[i];
			}
			TargetName = FText::FromString(DisplayText);
		}

		if(Target != nullptr)
		{
			FVector2D WantedScreenPos;
			bool bAimOnScreen = SceneView::ProjectWorldToViewpointRelativePosition(
				Player, Target.WorldLocation, /*out*/ WantedScreenPos
			);

			if(Target.TargetName.IsEmpty())
			{
				if(bAimOnScreen && bWasVisible)
					CrosshairWidget.SetVisibility(ESlateVisibility::Visible);
				else
					CrosshairWidget.SetVisibility(ESlateVisibility::Collapsed);

				EnemyCanvas.SetVisibility(ESlateVisibility::Collapsed);
			}
			else
			{
				if(bAimOnScreen && bWasVisible)
					EnemyCanvas.SetVisibility(ESlateVisibility::Visible);
				else
					EnemyCanvas.SetVisibility(ESlateVisibility::Collapsed);

				CrosshairWidget.SetVisibility(ESlateVisibility::Collapsed);
			}

			bWasVisible = bAimOnScreen;
		}
		else
		{
			EnemyCanvas.SetVisibility(ESlateVisibility::Collapsed);
			CrosshairWidget.SetVisibility(ESlateVisibility::Collapsed);
			bWasVisible = false;
		}
	}

	void OnTargetChanged(UDragonSwordCombatTargetComponent NewTarget)
	{
		if(NewTarget != nullptr)
		{
			bCurrentTargetHasName = !NewTarget.TargetName.IsEmpty();

			if(bCurrentTargetHasName)
			{
				GenerateRandomString(NewTarget.TargetName.ToString().Len());
				TargetName = FText::FromString(DistortedText);
				TargetString = NewTarget.TargetName.ToString();
				LastChangedTime = Time::GameTimeSeconds;
			}
		}
		else
		{
			bCurrentTargetHasName = false;
		}
		
		CurrentTarget = NewTarget;
	}

	void GenerateRandomString(int Length)
	{
		DistortedIndices.Reset();

		FString RandomString;

		for(int i = 0; i < Length; i++)
		{
			RandomString.AppendChar(GetRandomCharacter());
			DistortedIndices.Add(i);
		}

		DistortedText = RandomString;
	}

	private int16 GetRandomCharacter() const
	{
		return Characters[Math::RandRange(0, Characters.Num() - 1)];
	}

	private void GenerateCharactersArray()
	{
		Characters.Reset();

		// Upper case
		Characters.Add('A');
		Characters.Add('B');
		Characters.Add('C');
		Characters.Add('D');
		Characters.Add('E');
		Characters.Add('F');
		Characters.Add('G');
		Characters.Add('H');
		Characters.Add('I');
		Characters.Add('J');
		Characters.Add('K');
		Characters.Add('L');
		Characters.Add('M');
		Characters.Add('N');
		Characters.Add('O');
		Characters.Add('P');
		Characters.Add('Q');
		Characters.Add('R');
		Characters.Add('S');
		Characters.Add('T');
		Characters.Add('U');
		Characters.Add('V');
		Characters.Add('W');
		Characters.Add('X');
		Characters.Add('Y');
		Characters.Add('Z');

		// Lower case
		Characters.Add('a');
		Characters.Add('b');
		Characters.Add('c');
		Characters.Add('d');
		Characters.Add('e');
		Characters.Add('f');
		Characters.Add('g');
		Characters.Add('h');
		Characters.Add('i');
		Characters.Add('j');
		Characters.Add('k');
		Characters.Add('l');
		Characters.Add('m');
		Characters.Add('n');
		Characters.Add('o');
		Characters.Add('p');
		Characters.Add('q');
		Characters.Add('r');
		Characters.Add('s');
		Characters.Add('t');
		Characters.Add('u');
		Characters.Add('v');
		Characters.Add('w');
		Characters.Add('x');
		Characters.Add('y');
		Characters.Add('z');

		// Symbols
		Characters.Add('!');
		Characters.Add('@');
		Characters.Add('#');
		Characters.Add('$');
		Characters.Add('%');
		Characters.Add('&');
		Characters.Add('/');
		Characters.Add('(');
		Characters.Add(')');
		Characters.Add('=');
		Characters.Add('+');
		Characters.Add('?');
		Characters.Add('-');
		Characters.Add('*');
		Characters.Add('{');
		Characters.Add('[');
		Characters.Add(']');
		Characters.Add('}');
		Characters.Add('|');
		Characters.Add('<');
		Characters.Add('>');
		Characters.Add('.');
		Characters.Add(' ');
		Characters.Add('~');
		Characters.Add('^');

		// Accents
		Characters.Add('É');
		Characters.Add('é');
		Characters.Add('Å');
		Characters.Add('å');
		Characters.Add('Ä');
		Characters.Add('ä');
		Characters.Add('Ö');
		Characters.Add('ö');
	}
}